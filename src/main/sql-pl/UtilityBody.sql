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
 * Constant internalCache (For debug purposes)
 */
ALTER MODULE LOGGER ADD
  VARIABLE INTERNAL_CACHE ANCHOR LOGDATA.CONFIGURATION.KEY CONSTANT 'internalCache' @

/**
 * Constant secondsToRefresh to define the period fo refreshness.
 */
ALTER MODULE LOGGER ADD
  VARIABLE REFRESH_CONS ANCHOR LOGDATA.CONFIGURATION.KEY CONSTANT 'secondsToRefresh' @

/**
 * Constant for the defaultRootLevelId value.
 */
ALTER MODULE LOGGER ADD
  VARIABLE DEFAULT_ROOT_LEVEL_ID ANCHOR LOGDATA.CONFIGURATION.KEY CONSTANT 'defaultRootLevelId' @

/**
 * Constant for the autonomousLogging value for autonomous procedure to write
 * in the LOGS table.
 */
ALTER MODULE LOGGER ADD
  VARIABLE AUTONOMOUS_LOGGING ANCHOR LOGDATA.CONFIGURATION.KEY CONSTANT 'autonomousLogging' @

/**
 * Constant for the value of the default level.
 */
ALTER MODULE LOGGER ADD
  VARIABLE DEFAULT_LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID CONSTANT 3 @

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
  VARIABLE LAST_REFRESH TIMESTAMP DEFAULT NULL @

/**
 * Root's current level. TODO use cache
 */
ALTER MODULE LOGGER ADD
  VARIABLE ROOT_CURRENT_LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID @

/**
 * Configuration values type.
 */
ALTER MODULE LOGGER ADD
  TYPE CONF_VALUES_TYPE AS ANCHOR LOGDATA.CONFIGURATION.VALUE ARRAY [ANCHOR LOGDATA.CONFIGURATION.KEY] @

/**
 * Configuration values in memory.
 */
ALTER MODULE LOGGER ADD
  VARIABLE CONF_CACHE CONF_VALUES_TYPE @

/**
 * Logger's ID type.
 */
ALTER MODULE LOGGER ADD
  TYPE LOGGERS_ID_TYPE AS ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID ARRAY [ANCHOR COMPLETE_LOGGER_NAME] @

/**
 * Logger's names => ids cache.
 */
ALTER MODULE LOGGER ADD
  VARIABLE LOGGERS_ID_CACHE LOGGERS_ID_TYPE @

/**
 * Levels type. It is not possible to have an array of something different of
 * VARCHAR and INTEGER. Thus, it is not possible to anchor the LEVEL_ID.
 */
ALTER MODULE LOGGER ADD
  TYPE LEVELS_TYPE AS ANCHOR LOGDATA.LEVELS.NAME ARRAY [INTEGER] @

/**
 * Level's names and ids.
 */
ALTER MODULE LOGGER ADD
  VARIABLE LEVELS_CACHE LEVELS_TYPE @

/**
 * Row logger'data.
 */
ALTER MODULE LOGGER ADD
  TYPE LOGGERS_ROW AS ROW (
  NAME ANCHOR COMPLETE_LOGGER_NAME,
  LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY) @

/**
 * Logger'data type.
 */
ALTER MODULE LOGGER ADD
  TYPE LOGGERS_TYPE AS LOGGERS_ROW ARRAY [INTEGER] @

/**
 * Logger'data array.
 */
ALTER MODULE LOGGER ADD
  VARIABLE LOGGERS_CACHE LOGGERS_TYPE @

/**
 * Unload configuration. This is useful for debugging, but it should not called
 * used in production.
 *
 * PRE
 *   No conditions.
 * POS
 *   The caches are emptied.
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
  SET CONF_CACHE = ARRAY_DELETE(CONF_CACHE);
  SET LOGGERS_ID_CACHE = ARRAY_DELETE(LOGGERS_ID_CACHE);
  SET LEVELS_CACHE = ARRAY_DELETE(LEVELS_CACHE);
  SET LOGGERS_CACHE = ARRAY_DELETE(LOGGERS_CACHE);
  -- Sets a reference date 1970-01-01.
  SET LAST_REFRESH = DATE(719163);
  SET LOADED = FALSE;
 END P_UNLOAD_CONF @ 

/**
 * Refreshes the configuration cache immediately.
 *
 * PRE
 *   No preconditions.
 * POS
 *   The caches holds the most recent information.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE REFRESH_CACHE (
  )
  LANGUAGE SQL
  SPECIFIC P_REFRESH_CACHE
  DYNAMIC RESULT SETS 2
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_REFRESH_CACHE: BEGIN
  DECLARE VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
  DECLARE LVL ANCHOR LOGDATA.LEVELS.LEVEL_ID;
  DECLARE NAME ANCHOR LOGDATA.LEVELS.NAME;
  DECLARE AT_END BOOLEAN; -- End of the cursor.
  DECLARE CONF CURSOR FOR
    SELECT KEY, VALUE
    FROM LOGDATA.CONFIGURATION
    OPTIMIZE FOR 10 ROWS
    WITH UR;
  DECLARE LVLS CURSOR FOR
    SELECT LEVEL_ID, NAME
    FROM LOGDATA.LEVELS
    OPTIMIZE FOR 10 ROWS
    WITH UR;
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET AT_END = TRUE;
  -- Clears the current configuration.
  CALL UNLOAD_CONF();
  
  -- Reads current configuration.
  -- FIXME: ARRAY_AGG is not supported in previous versions to v10.1fp2
  -- SELECT ARRAY_AGG(KEY, VALUE) INTO CONFIGURATION
  --  FROM LOGDATA.CONFIGURATION
  --  WITH UR;
  SET AT_END = FALSE;
  OPEN CONF;
  FETCH CONF INTO KEY, VALUE;
  WHILE (AT_END = FALSE) DO
   SET CONF_CACHE[KEY] = VALUE;
   FETCH CONF INTO KEY, VALUE;
  END WHILE;
  -- Reads the levels
  SET AT_END = FALSE;
  OPEN LVLS;
  FETCH LVLS INTO LVL, NAME;
  WHILE (AT_END = FALSE) DO
   SET LEVELS_CACHE[CHAR(LVL)] = NAME;
   FETCH LVLS INTO LVL, NAME;
  END WHILE;
  -- Reads root's current levels.
  SELECT C.LEVEL_ID INTO ROOT_CURRENT_LEVEL
    FROM LOGDATA.CONF_LOGGERS C
    WHERE C.LOGGER_ID = 0
    FETCH FIRST 1 ROW ONLY
    WITH UR;

  SET LOADED = TRUE;
  -- Sets the most recent configuration read as now.
  SET LAST_REFRESH = CURRENT TIMESTAMP;
 END P_REFRESH_CACHE @

/**
 * Verifies if the configuration should be reloaded, and if necessary, then
 * reloads the configurations.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE CHECK_REFRESH()
  LANGUAGE SQL
  SPECIFIC P_CHECK_REFRESH
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_CHECK_REFRESH: BEGIN
  DECLARE SECS SMALLINT DEFAULT 60;
  DECLARE EPOCH TIMESTAMP;
   -- Sets the quantity of seconds before refresh. 60 seconds by default.
   REFRESH: BEGIN
    -- Handle for the second time the function is called and the param has not
    -- been defined.
    DECLARE CONTINUE HANDLER FOR SQLSTATE '2202E'
      SET SECS = 60;
    -- There is an invalid value.
    DECLARE CONTINUE HANDLER FOR SQLSTATE '22018'
      SET SECS = 60;
    
    SET SECS = INT(CONF_CACHE[REFRESH_CONS]);
    IF (SECS IS NULL) THEN
     SET SECS = 60;
    END IF;
   END REFRESH;

   -- Sets a reference date 1970-01-01.
   SET EPOCH = DATE(719163);
   IF (LOADED = FALSE OR COALESCE(LAST_REFRESH, EPOCH) + SECS SECONDS < CURRENT TIMESTAMP) THEN
    -- Refreshes the configuration
    CALL LOGGER.REFRESH_CACHE();
   END IF;
 END P_CHECK_REFRESH @

/**
 * Returns the name of a level of the given ID.
 *
 * IN LVL_ID
 *   Level id to analyze.
 * RETURN The text that represents the id.
 */
ALTER MODULE LOGGER ADD
  FUNCTION GET_LEVEL_NAME (
  IN LVL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID
  )
  RETURNS ANCHOR LOGDATA.LEVELS.NAME
  LANGUAGE SQL
  SPECIFIC F_GET_LEVEL_NAME
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 F_GET_LEVEL_NAME: BEGIN
  DECLARE RET ANCHOR LOGDATA.LEVELS.NAME;

  -- Checks if internal cache should be used.
  IF (CACHE = TRUE) THEN
   CALL CHECK_REFRESH();

   SET RET = LEVELS_CACHE[LVL_ID];
  ELSE -- Does not use the internal cache but a query.
   SELECT L.NAME INTO RET
     FROM LOGDATA.LEVELS L
     WHERE L.LEVEL_ID = LVL_ID
     FETCH FIRST 1 ROW ONLY
     WITH UR;
  END IF;

  RETURN RET;
 END F_GET_LEVEL_NAME @

/**
 * Tests if the given ID is present in the Levels array.
 *
 * IN LVL_ID
 *   Level id to analyze.
 * RETURN The true if the value is in the array. False otherwise.
 */
ALTER MODULE LOGGER ADD
  FUNCTION EXIST_LEVEL (
  IN LVL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID
  )
  RETURNS BOOLEAN
  LANGUAGE SQL
  SPECIFIC F_EXIST_LEVEL
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 F_EXIST_LEVEL: BEGIN
  DECLARE RET BOOLEAN DEFAULT FALSE;
  DECLARE ID ANCHOR LOGDATA.LEVELS.LEVEL_ID;

  -- Checks if internal cache should be used.
  IF (CACHE = TRUE) THEN
   CALL CHECK_REFRESH();

   SET RET = ARRAY_EXISTS(LEVELS_CACHE, LVL_ID);
  ELSE -- Does not use the internal cache but a query.
   SELECT L.LEVEL_ID INTO ID
     FROM LOGDATA.LEVELS L
     WHERE L.LEVEL_ID = LVL_ID
     FETCH FIRST 1 ROW ONLY
     WITH UR;
   IF (ID IS NOT NULL) THEN
    SET RET = TRUE;
   END IF;
  END IF;

  RETURN RET;
 END F_EXIST_LEVEL @

/**
 * Function that returns the value of the given key from the configuration
 * table.
 *
 * IN KEY
 *   Identification of the key/value parameter of the configuration table.
 * RETURNS The associated value of the given key. NULL if there is not a key
 * with that value.
 * PRE
 *   No preconditions.
 * POS
 *   The returned value correspond to the given value if exist.
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

  -- Checks if internal cache should be used.
  IF (CACHE = TRUE) THEN
   CALL CHECK_REFRESH();

   BEGIN
    -- NULL if the key is not in the configuration.
    DECLARE CONTINUE HANDLER FOR SQLSTATE '2202E'
      SET RET = NULL;

    SET RET = CONF_CACHE[GIVEN_KEY];
   END;
  ELSE -- Does not use the internal cache but a query.
   SELECT C.VALUE INTO RET
     FROM LOGDATA.CONFIGURATION C
     WHERE C.KEY = GIVEN_KEY
     FETCH FIRST 1 ROW ONLY
     WITH UR;
  END IF;

  RETURN RET;
 END F_GET_VALUE @

/**
 * Activates the cache. Cleans any previous value on the cache.
 *
 * PRE
 *   No preconditions.
 * POS
 *   The cache holds the most recent information from the table.
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
  --IF (VAL <> LOGGER.VAL_TRUE) THEN
  -- SIGNAL SQLSTATE VALUE 'LG002'
  --   SET MESSAGE_TEXT = 'Invalid configuration state';
  --END IF;
  SET CACHE = TRUE;
 END P_ACTIVATE_CACHE @

/**
 * Cleans the cache, and deactives it.
 *
 * PRE
 *   No preconditions.
 * POS
 *   The cache is emptied.
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
  --IF (VAL = LOGGER.VAL_TRUE) THEN
  -- SIGNAL SQLSTATE VALUE 'LG002'
  --   SET MESSAGE_TEXT = 'Invalid configuration state';
  --END IF;
  CALL UNLOAD_CONF();
  SET CACHE = FALSE;
 END P_DEACTIVATE_CACHE @

/**
 * Returns a character representation of the given boolean.
 *
 * IN VALUE
 *   Value to convert.
 * RETURN
 *   The corresponding represtation of the given boolean.
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
 F_BOOL_TO_CHAR: BEGIN
  DECLARE RET CHAR(5) DEFAULT 'FALSE';
  
  IF (VALUE IS NULL) THEN
    SET RET = 'NULL';
  ELSEIF (VALUE = TRUE) THEN
   SET RET = 'TRUE';
  END IF;
  RETURN RET;
 END F_BOOL_TO_CHAR @

/**
 * Returns all data of a given logger.
 *
 * IN LOG_ID
 *   Logger to analyze.
 * RETURN The data of the logger.
 */
ALTER MODULE LOGGER ADD
  FUNCTION GET_LOGGER_DATA (
  IN LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  )
  RETURNS LOGGERS_ROW
  LANGUAGE SQL
  SPECIFIC F_GET_LOGGER_DATA
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 F_GET_LOGGER_DATA: BEGIN
  DECLARE COMPLETE_NAME ANCHOR COMPLETE_LOGGER_NAME;
  DECLARE LVL ANCHOR LOGDATA.LEVELS.LEVEL_ID;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE RET LOGGERS_ROW;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '2202E'
    SET LVL = NULL;

  -- Checks if internal cache should be used.
  IF (CACHE = TRUE) THEN
   CALL CHECK_REFRESH();

   SET RET = LOGGERS_CACHE[LOG_ID];
   SET COMPLETE_NAME = RET.NAME;
  END IF;
  -- If cache is not active, or it has not been found on it.
  IF (CACHE = FALSE OR LVL IS NULL) THEN
   SELECT LEVEL_ID, HIERARCHY INTO LVL, HIERARCHY
     FROM LOGDATA.CONF_LOGGERS_EFFECTIVE E
     WHERE E.LOGGER_ID = LOG_ID
     FETCH FIRST 1 ROW ONLY
     WITH UR;
   SET RET.NAME = COMPLETE_NAME;
   SET RET.LEVEL_ID = LVL;
   SET RET.HIERARCHY = HIERARCHY;
   SET LOGGERS_CACHE[LOG_ID] = RET;
  END IF;

  RETURN RET;
 END F_GET_LOGGER_DATA @

/**
 * Retrieves the complete logger name for a given logged id.
 *
 * IN LOG_ID
 *   Identification of the logger in the effective table.
 * RETURNS the complete name of the logger (recursive.)
 * TESTS
 *   TestsGetLoggerName: Verifies different outputs for this function.
 * PRE
 *   ROOT is defined.
 * POS
 *   The returned name matches the hierarchy. If the inverse function of
 *   GET_LOGGER.
 */
ALTER MODULE LOGGER ADD
 FUNCTION GET_LOGGER_NAME (
  IN LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  ) RETURNS ANCHOR COMPLETE_LOGGER_NAME
  LANGUAGE SQL
  PARAMETER CCSID UNICODE
  SPECIFIC F_GET_NAME
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  READS SQL DATA
 F_GET_NAME: BEGIN
  DECLARE LOG_ROW LOGGERS_ROW;
  DECLARE COMPLETE_NAME ANCHOR COMPLETE_LOGGER_NAME;
  DECLARE PARENT ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE RETURNED ANCHOR COMPLETE_LOGGER_NAME;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '2202E'
    SET COMPLETE_NAME = NULL;

  SET LOG_ROW = LOGGERS_CACHE[LOG_ID];
  SET COMPLETE_NAME = LOG_ROW.NAME;
  IF (COMPLETE_NAME IS NULL) THEN
   -- The logger is ROOT.
   IF (LOG_ID = 0) THEN
    SET COMPLETE_NAME = 'ROOT';
    ELSEIF (LOG_ID > 0) THEN
    -- Retrieves the id of the parent logger.
    SELECT C.PARENT_ID, C.NAME INTO PARENT, NAME
      FROM LOGDATA.CONF_LOGGERS C
      WHERE C.LOGGER_ID = LOG_ID
      FETCH FIRST 1 ROW ONLY
      WITH UR;

    IF (PARENT IS NOT NULL) THEN
     SET RETURNED = GET_LOGGER_NAME(PARENT) ;
     -- The parent is ROOT, thus do not concatenate.
     IF (RETURNED <> 'ROOT') THEN
      SET COMPLETE_NAME = RETURNED || '.' || NAME;
     ELSE
      SET COMPLETE_NAME = NAME;
     END IF;
    ELSE
     SET COMPLETE_NAME = 'Unknown';
    END IF;
   ELSEIF (LOG_ID = -1 OR LOG_ID IS NULL) THEN
    -- The logger is internal
    SET COMPLETE_NAME = '-internal-';
   ELSE
    SET COMPLETE_NAME = '-INVALID-';
   END IF;
   IF (LOG_ID IS NOT NULL) THEN
    SET LOG_ROW.NAME = COMPLETE_NAME;
    SET LOGGERS_CACHE[LOG_ID] = LOG_ROW;
   END IF;
  END IF;
  RETURN COMPLETE_NAME;
 END F_GET_NAME @

/**
 * Modifies the descendancy of the provided logger changing the level to the
 * given one.
 *
 * IN PARENT
 *   Parent of the descendancy to be changed.
 * IN LEVEL
 *   Log level to be assigned to all descendancy.
 * TESTS
 *   TestsMessages: Checks the output of the error.
 * PRE
 *   ROOT exists and Levels are defined.
 * POS
 *   The Effective table reflects the new values.
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
    OPTIMIZE FOR 20 ROW
    WITH CS
    FOR UPDATE
    DO
   -- Checks if the level has a configured level, or it is inherited.
   SELECT LEVEL_ID INTO LVL_ID
     FROM LOGDATA.CONF_LOGGERS
     WHERE LOGGER_ID = LOG_ID
     FETCH FIRST 1 ROW ONLY
     WITH CS;
   IF (LVL_ID IS NULL) THEN
    -- Updates the current logger_id (son.)
    UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
      SET LEVEL_ID = LEVEL
      WHERE LOGGER_ID = LOG_ID
      WITH CS;
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
 * PRE
 *   No conditions.
 * POS
 *   The returned value corresponds to the value registered in the database.
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
    DECLARE CONTINUE HANDLER FOR SQLSTATE '22018'
      SET RET = DEFAULT_LEVEL;

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
 * TESTS
 *   TestsFunctionGetDefinedParent checks different inputs of this function.
 *   TestsMessages: Checks the output of the error.
 * PRE
 *   ROOT is registered in the databas and levels are defined.
 * POS
 *   The returned level correspond to the closer ascendant in the hierarchy.
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
     FETCH FIRST 1 ROW ONLY
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
     WHERE LOGGER_ID = (
      SELECT PARENT_ID
      FROM LOGDATA.CONF_LOGGERS
      WHERE LOGGER_ID = SON_ID
      FETCH FIRST 1 ROW ONLY
      WITH UR)
     FETCH FIRST 1 ROW ONLY
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

