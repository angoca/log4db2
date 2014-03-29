--#SET TERMINATOR @

/*
Copyright (c) 2012 - 2014, Andres Gomez Casanova (AngocA)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

SET CURRENT SCHEMA LOGGER_1B @

/**
 * Implementation of the routines to use log4db2.
 *
 * Version: 2014-02-14 1-Alpha
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

/**
 * Constanct internalCache
 */
ALTER MODULE LOGGER ADD
  VARIABLE INTERNAL_CACHE ANCHOR LOGDATA.CONFIGURATION.KEY CONSTANT 'internalCache' @

/**
 * Constant logInternals
 */
ALTER MODULE LOGGER ADD
  VARIABLE REFRESH_CONS ANCHOR LOGDATA.CONFIGURATION.KEY CONSTANT 'secondsToRefresh' @

/**
 * Constant for the defaultRootLevelId value.
 */
ALTER MODULE LOGGER ADD
  VARIABLE DEFAULT_ROOT_LEVEL_ID ANCHOR LOGDATA.CONFIGURATION.KEY CONSTANT 'defaultRootLevelId' @

/**
 * Variable to indicate the use of internal cache.
 */
ALTER MODULE LOGGER ADD
  VARIABLE CACHE BOOLEAN DEFAULT TRUE @

/**
 * Variable that indicates if the configuration cache has been loaded.
 */
ALTER MODULE LOGGER ADD
  VARIABLE LOADED BOOLEAN DEFAULT FALSE @

/**
 * Variable for the last time the configuration was loaded.
 */
ALTER MODULE LOGGER ADD
  VARIABLE LAST_REFRESH TIMESTAMP DEFAULT CURRENT TIMESTAMP @

/**
 * Configuration values type.
 */
ALTER MODULE LOGGER ADD
  TYPE CONF_VALUES_TYPE AS ANCHOR LOGDATA.CONFIGURATION.VALUE ARRAY [ANCHOR LOGDATA.CONFIGURATION.KEY] @

/**
 * Configuration values in memory.
 */
ALTER MODULE LOGGER ADD
  VARIABLE CONFIGURATION CONF_VALUES_TYPE @

/**
 * Complete logger name.
 */
ALTER MODULE LOGGER ADD
  VARIABLE COMPLETE_LOGGER_NAME VARCHAR(256) @

/**
 * Loggers type.
 */
ALTER MODULE LOGGER ADD
  TYPE LOGGERS_TYPE AS ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID ARRAY [ANCHOR COMPLETE_LOGGER_NAME] @

/**
 * Logger's names and ids.
 */
ALTER MODULE LOGGER ADD
  VARIABLE LOGGERS_CACHE LOGGERS_TYPE @

/**
 * Retrieves the complete logger name for a given logged id.
 *
 * IN LOG_ID
 *  Identification of the logger in the effective table.
 * RETURNS the complete name of the logger (recursive.)
 */
ALTER MODULE LOGGER ADD
 FUNCTION GET_LOGGER_NAME (
  IN LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  ) RETURNS VARCHAR(256)
  -- XXX: DB2 error when temporal capabilities are activated.
  -- ) RETURNS ANCHOR COMPLETE_LOGGER_NAME
  LANGUAGE SQL
  PARAMETER CCSID UNICODE
  SPECIFIC F_GET_NAME
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  READS SQL DATA
 F_GET_NAME: BEGIN
  DECLARE COMPLETE_NAME ANCHOR COMPLETE_LOGGER_NAME;
  DECLARE PARENT ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE RETURNED ANCHOR COMPLETE_LOGGER_NAME;
  
  -- The logger is ROOT.
  IF (LOG_ID = 0) THEN
   SET COMPLETE_NAME = 'ROOT';
  ELSEIF (LOG_ID = -1 OR LOG_ID IS NULL) THEN
   -- The logger is internal
   SET COMPLETE_NAME = '-internal-';
  ELSE
   -- Retrieves the id of the parent logger.
   SELECT C.PARENT_ID, C.NAME INTO PARENT, NAME
     FROM LOGDATA.CONF_LOGGERS C
     WHERE C.LOGGER_ID = LOG_ID
     WITH UR;

   SET RETURNED = GET_LOGGER_NAME (PARENT) ;
   -- The parent is ROOT, thus do not concatenate.
   IF (RETURNED <> 'ROOT') THEN
    SET COMPLETE_NAME = RETURNED || '.' || NAME;
   ELSE
      SET COMPLETE_NAME = NAME;
   END IF;
  END IF;
  
  RETURN COMPLETE_NAME;
 END F_GET_NAME @

/**
 * Unload configuration. This is useful for tests, but it should not called
 * used in production.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE UNLOAD_CONF (
  )
  LANGUAGE SQL
  SPECIFIC P_UNLOAD_CONF
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_UNLOAD_CONF: BEGIN
  SET CONFIGURATION = ARRAY_DELETE(CONFIGURATION);
  SET LAST_REFRESH = CURRENT TIMESTAMP;
  SET CACHE = TRUE;
  SET LOADED = FALSE;
 END P_UNLOAD_CONF @ 

/**
 * Refreshes the configuration cache immediately.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE REFRESH_CONF (
  )
  LANGUAGE SQL
  SPECIFIC P_REFRESH_CONF
  DYNAMIC RESULT SETS 2
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_REFRESH_CONF: BEGIN
  DECLARE VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
  DECLARE AT_END BOOLEAN; -- End of the cursor.
  DECLARE SIZE SMALLINT;
  DECLARE CONF CURSOR FOR
    SELECT KEY, VALUE
    FROM LOGDATA.CONFIGURATION
    WITH UR;
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET AT_END = TRUE;

  -- Clears the current configuration.
  CALL UNLOAD_CONF();
  -- Reads current configuration.
  SET AT_END = FALSE;
  OPEN CONF;
  FETCH CONF INTO KEY, VALUE;
  WHILE (AT_END = FALSE) DO
   SET CONFIGURATION[KEY] = VALUE;
   FETCH CONF INTO KEY, VALUE;
  END WHILE;
  -- Sets the last configuration read as now.
  SET LAST_REFRESH = CURRENT TIMESTAMP;
 END P_REFRESH_CONF @

/**
 * Function that returns the value of the given key from the configuration
 * table.
 *
 * IN KEY
 *  Identification of the key/value parameter of the configuration table.
 * RETURNS The associated value of the given key. NULL if there is not a key
 * with that value.
 */
ALTER MODULE LOGGER ADD
  FUNCTION GET_VALUE (
  IN GIVEN_KEY ANCHOR LOGDATA.CONFIGURATION.KEY
  )
  RETURNS ANCHOR LOGDATA.CONFIGURATION.VALUE
  LANGUAGE SQL
  SPECIFIC F_GET_VALUE
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 F_GET_VALUE: BEGIN
  DECLARE RET ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE SECS SMALLINT DEFAULT 60;
  DECLARE EPOCH TIMESTAMP;

  -- Checks if internal cache should be used.
  IF (CACHE = TRUE) THEN

   -- Sets the quantity of seconds before refresh. 60 seconds by default.
   REFRESH: BEGIN
    -- Handle for the second time the function is called and the param has not
    -- been defined.
    DECLARE CONTINUE HANDLER FOR SQLSTATE '2202E'
      SET SECS = 60;
    SET SECS = INT(CONFIGURATION[REFRESH_CONS]);
    IF (SECS IS NULL) THEN
     SET SECS = 60;
    END IF;
   END REFRESH;

   -- Sets a reference date 1970-01-01.
   SET EPOCH = DATE(719163);
   IF (COALESCE(LAST_REFRESH, EPOCH) + SECS SECONDS < CURRENT TIMESTAMP OR LOADED = FALSE) THEN
    -- Refreshes the configuration
    CALL LOGGER.REFRESH_CONF ();
    SET LOADED = TRUE;
   END IF;

   BEGIN
    -- NULL if the key is not in the configuration.
    DECLARE EXIT HANDLER FOR SQLSTATE '2202E'
      SET RET = NULL;

    SET RET = CONFIGURATION[GIVEN_KEY];
   END;
  ELSE -- Does not use the internal cache but a query.
   SELECT C.VALUE INTO RET
     FROM LOGDATA.CONFIGURATION C
     WHERE C.KEY = GIVEN_KEY;
  END IF;

  RETURN RET;
 END F_GET_VALUE @

/**
 * Deletes a value in the loggers cache.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE DELETE_LOGGER_CACHE (
  IN LOGGER ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  )
  LANGUAGE SQL
  SPECIFIC P_DELETE_CACHE
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_DELETE_CACHE: BEGIN
  SET LOGGERS_CACHE = ARRAY_DELETE(LOGGERS_CACHE, LOGGER);
 END P_DELETE_CACHE @

/**
 * Deletes a value in the loggers cache.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE DELETE_ALL_LOGGER_CACHE (
  )
  LANGUAGE SQL
  SPECIFIC P_DELETE_ALL_CACHE
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_DELETE_ALL_CACHE: BEGIN
  SET LOGGERS_CACHE = ARRAY_DELETE(LOGGERS_CACHE);
 END P_DELETE_ALL_CACHE @

/**
 * Activates the cache. Cleans any previous value on the cache.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE ACTIVATE_CACHE (
  )
  LANGUAGE SQL
  SPECIFIC P_ACTIVATE_CACHE
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ACTIVATE_CACHE: BEGIN
  DECLARE VAL ANCHOR LOGDATA.CONFIGURATION.VALUE;

  -- NOTE: Active for debugging.
  -- Check that the configuration variable is true
  --SELECT VALUE INTO VAL
  --  FROM LOGDATA.CONFIGURATION
  --  WHERE KEY = INTERNAL_CACHE;
  --IF (VAL <> 'true') THEN
  -- SIGNAL SQLSTATE VALUE 'LG002'
  --   SET MESSAGE_TEXT = 'Invalid configuration state';
  --END IF;
  SET CACHE = TRUE;
  SET LOADED = FALSE;
  -- Cleans the cache
  SET LOGGERS_CACHE = ARRAY_DELETE(LOGGERS_CACHE);
 END P_ACTIVATE_CACHE @

/**
 * Cleans the cache, and deactives it.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE DEACTIVATE_CACHE (
  )
  LANGUAGE SQL
  SPECIFIC P_DEACTIVATE_CACHE
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_DEACTIVATE_CACHE: BEGIN
  DECLARE VAL ANCHOR LOGDATA.CONFIGURATION.VALUE;

  -- NOTE: Active for debugging.
  -- Check that the configuration variable is false
  --SELECT VALUE INTO VAL
  --  FROM LOGDATA.CONFIGURATION
  --  WHERE KEY = INTERNAL_CACHE;
  --IF (VAL = 'true') THEN
  -- SIGNAL SQLSTATE VALUE 'LG002'
  --   SET MESSAGE_TEXT = 'Invalid configuration state';
  --END IF;
  SET CACHE = FALSE;
  SET LOADED = FALSE;
  -- Cleans the cache
  SET LOGGERS_CACHE = ARRAY_DELETE(LOGGERS_CACHE);
 END P_DEACTIVATE_CACHE @

/**
 * Procedure that dumps the configuration. It returns two result sets. The
 * first is a one-row result set providing the information when the
 * configuration was loaded, and when it will be reloaded (with its frequency).
 * In the other result set, it shows the key-values from the configuration, if
 * this was already loaded, otherwise a descriptive message appears.
 * This procedure shows the configuration, but it does not reload it, for this
 * reason, the next refresh time could be in the past. Please note that the
 * get_value procedure is the only one that refreshes the configuration.
 * If the cache is in false in the configuration, but the configuration has
 * not been read, it will show that the cache is active (by default).
 */
ALTER MODULE LOGGER ADD
  PROCEDURE SHOW_CONF (
  )
  LANGUAGE SQL
  SPECIFIC P_SHOW_CONF
  DYNAMIC RESULT SETS 2
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_SHOW_CONF: BEGIN
  -- Creates the cursor for the configuration refreshness.
  BEGIN
   DECLARE SECS SMALLINT;
   DECLARE STMT VARCHAR(512);
   DECLARE REF CURSOR
     WITH RETURN TO CALLER
     FOR RS;
   -- Sets the value for the seconds.
   BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '2202E'
      SET SECS = -1;
    SET SECS = INT(CONFIGURATION[REFRESH_CONS]);
    IF (SECS IS NULL) THEN
     SET SECS = -1;
    END IF;
   END;
   -- Creates and prepares a dynamic query.
   SET STMT = 'SELECT CASE WHEN LOADED = FALSE THEN ''Unknown'' '
     || 'WHEN CACHE = TRUE THEN ''true'' '
     || 'ELSE ''false'' END AS INTERNAL_CACHE_ACTIVATED, '
     || 'LAST_REFRESH AS LAST_REFRESH, '
     || SECS || ' AS FREQUENCY, '
     || 'CASE WHEN ' || SECS || ' = -1 OR CACHE = FALSE THEN ''Not defined'' '
     || 'ELSE CHAR(LAST_REFRESH + ' || SECS || ' SECONDS) '
     || 'END AS NEXT_REFRESH, '
     || '''' || CURRENT TIMESTAMP || ''' AS CURRENT_TIME '
     || 'FROM SYSIBM.SYSDUMMY1';
   PREPARE RS FROM STMT;
   OPEN REF;
  END;

  -- Creates a cursor for configuration values.
  BEGIN
   DECLARE CARD SMALLINT;
   DECLARE CONF CURSOR
     WITH RETURN TO CLIENT 
     FOR 
     SELECT T.KEY AS KEY, T.VALUE AS VALUE
     FROM UNNEST(CONFIGURATION) AS T(KEY, VALUE);
   DECLARE NOTHING CURSOR
     WITH RETURN TO CLIENT
     FOR
     SELECT 'Configuration not loaded' AS MESSAGE
     FROM SYSIBM.SYSDUMMY1;

   -- Checks if the configuration was already loaded.
   SET CARD = CARDINALITY(CONFIGURATION);
   IF (CARD > 0) THEN
    OPEN CONF;
   ELSE
    OPEN NOTHING;
   END IF;
  END;
 END P_SHOW_CONF @

/**
 * This is a helper procedure that shows the content of the logger cache if it
 * is currently used.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE SHOW_CACHE (
  )
  LANGUAGE SQL
  SPECIFIC P_SHOW_CACHE
  DYNAMIC RESULT SETS 2
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_SHOW_CACHE: BEGIN
  DECLARE STMT VARCHAR(512);
  DECLARE CACHE_CURSOR CURSOR
    WITH RETURN TO CLIENT 
    FOR
    SELECT SUBSTR(T.LOGGER, 1, 64) AS LOGGER_NAME, T.ID AS LOGGER_ID
    FROM UNNEST(LOGGERS_CACHE) AS T(LOGGER, ID);
  DECLARE DESC_CURSOR CURSOR
    WITH RETURN TO CALLER
    FOR RS;
  SET STMT = 'SELECT ''Cardinality: ' || COALESCE(CARDINALITY(LOGGERS_CACHE), -1) || ''' FROM SYSIBM.SYSDUMMY1';
  PREPARE RS FROM STMT;
  OPEN DESC_CURSOR;
  OPEN CACHE_CURSOR;
 END P_SHOW_CACHE @

/**
 * Returns a character representation of the given boolean.
 */
ALTER MODULE LOGGER ADD
  FUNCTION BOOL_TO_CHAR(
  IN VALUE BOOLEAN
  ) RETURNS CHAR(5)
  LANGUAGE SQL
  SPECIFIC F_BOOL_TO_CHAR
  DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 F_GET_DEFAULT_LEVEL: BEGIN
  DECLARE RET CHAR(5) DEFAULT 'FALSE';
  
  IF (VALUE IS NULL) THEN
    SET RET = 'NULL';
  ELSEIF (VALUE = TRUE) THEN
   SET RET = 'TRUE';
  END IF;
  RETURN RET;
 END F_GET_DEFAULT_LEVEL @

/**
 * Modifies the descendancy of the provided logger changing the level to the
 * given one.
 *
 * IN PARENT
 *   Parent of the descendancy to be changed.
 * IN LEVEL
 *   Log level to be assigned to all descendancy.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE MODIFY_DESCENDANTS (
  IN PARENT ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID
  )
  LANGUAGE SQL
  SPECIFIC P_MODIFY_DESCENDANTS
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_MODIFY_DESCENDANTS: BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE LVL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID;

  -- Debug
  -- INSERT INTO LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 5, -1, 'aFLAG 5 = ' || coalesce (PARENT, -1) || '=' || coalesce (LEVEL, -1));

  IF (PARENT IS NULL OR PARENT < 0 OR LEVEL IS NULL OR LEVEL < 0) THEN
   SIGNAL SQLSTATE VALUE 'LG0P1'
     SET MESSAGE_TEXT = 'Invalid given parameter: PARENT or LEVEL ';
  END IF;
  -- Analyzes all sons for the given parent.
  FOR F AS C CURSOR FOR
    SELECT LOGGER_ID AS LOG_ID
    FROM LOGDATA.CONF_LOGGERS
    WHERE PARENT_ID = PARENT
    FOR UPDATE
    DO
   -- Checks if the level has a configured level, or it is inherited.
   SELECT LEVEL_ID INTO LVL_ID
     FROM LOGDATA.CONF_LOGGERS
     WHERE LOGGER_ID = LOG_ID;
   IF (LVL_ID IS NULL) THEN
    -- Updates the current logger_id (son.)
    UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
      SET LEVEL_ID = LEVEL
      WHERE LOGGER_ID = LOG_ID;
    -- Modifies the descendant level (recursion).
    BEGIN
     DECLARE STMT STATEMENT;
     PREPARE STMT FROM 'CALL MODIFY_DESCENDANTS (?, ?)';
     EXECUTE STMT USING LOG_ID, LEVEL;
    END;
   END IF;
  END FOR;
 END P_MODIFY_DESCENDANTS @

/**
 * Function that returns the default logger level.
 * NOTE: If the levels are changed, this function should reflect those
 * modifications.
 *
 * RETURNS The configuration level for ROOT logger.
 */
ALTER MODULE LOGGER ADD
  FUNCTION GET_DEFAULT_LEVEL (
  ) RETURNS ANCHOR LOGDATA.LEVELS.LEVEL_ID
  LANGUAGE SQL
  SPECIFIC F_GET_DEFAULT_LEVEL
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 F_GET_DEFAULT_LEVEL: BEGIN
  DECLARE RET ANCHOR LOGDATA.LEVELS.LEVEL_ID;
  DECLARE VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

  -- Debug
  -- INSERT INTO LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 5, -1, 'aFLAG 6');

  SET VALUE = LOGGER.GET_VALUE(DEFAULT_ROOT_LEVEL_ID);
  SET RET = CAST(VALUE AS SMALLINT);
  RETURN RET;
 END F_GET_DEFAULT_LEVEL @

/**
 * Function that retrieves the defined log level from the closer ascendency.
 *
 * IN SON_ID
 *   Logger id that will be analyzed to find a ascendency with a defined log
 *   level.
 * RETURNS The log level configured to a ascendancy or the default value.
 */
ALTER MODULE LOGGER ADD
  FUNCTION GET_DEFINED_PARENT_LOGGER (
  IN SON_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  ) RETURNS ANCHOR LOGDATA.LEVELS.LEVEL_ID
  SPECIFIC F_GET_DEFINED_PARENT_LOGGER
  MODIFIES SQL DATA
 F_GET_DEFINED_PARENT_LOGGER: BEGIN
  DECLARE RET ANCHOR LOGDATA.LEVELS.LEVEL_ID;
  DECLARE PARENT ANCHOR LOGDATA.CONF_LOGGERS.PARENT_ID;
  DECLARE EXISTS SMALLINT DEFAULT 0;

  -- Debug
  -- INSERT INTO LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
  --   (GENERATE_UNIQUE(), 5, -1, '>GDP - son ' || coalesce (SON_ID, -1));

  IF (SON_ID IS NULL OR SON_ID < 0) THEN
   SIGNAL SQLSTATE VALUE 'LG0F1'
     SET MESSAGE_TEXT = 'Invalid given parameter: SON_ID';
  ELSEIF (SON_ID = 0) THEN
   -- Asking for the level for ROOT.
   SELECT LEVEL_ID INTO RET
     FROM LOGDATA.CONF_LOGGERS
     WHERE LOGGER_ID = 0
     WITH UR;
   IF (RET IS NULL) THEN
    -- ROOT is not configured, getting the default value.
    SET RET = GET_DEFAULT_LEVEL();

    -- Debug
    -- INSERT INTO LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
    --   (GENERATE_UNIQUE(), 5, -1, ' GDP - default ' || coalesce (RET, -1));

   END IF;
  ELSE
   -- Asking for a value different to ROOT.
   -- Retrieving the configured level for the parent of the given son.
   SELECT LEVEL_ID, LOGGER_ID INTO RET, PARENT
     FROM LOGDATA.CONF_LOGGERS
     WHERE LOGGER_ID = (SELECT PARENT_ID
     FROM LOGDATA.CONF_LOGGERS
     WHERE LOGGER_ID = SON_ID)
     WITH UR;
   IF (RET IS NULL) THEN

    -- Debug
    -- INSERT INTO LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
    --  (GENERATE_UNIQUE(), 5, -1, ' GDP - parent ' || coalesce (PARENT, -1));

    -- The parent has not a configured level, doing a recursion.
    BEGIN
     DECLARE STMT STATEMENT;
     PREPARE STMT FROM 'SET ? = GET_DEFINED_PARENT_LOGGER(?)';
     EXECUTE STMT INTO RET USING PARENT;
    END;
   END IF;
  END IF;

  -- Debug
  -- INSERT INTO LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
  --   (GENERATE_UNIQUE(), 5, -1, '<GDP - ret ' || coalesce (RET, -1));

  RETURN RET;
 END F_GET_DEFINED_PARENT_LOGGER @

