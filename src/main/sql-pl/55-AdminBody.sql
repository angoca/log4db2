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

SET CURRENT SCHEMA LOGGER_1RC @

/**
 * Implementation of the administrative routines of log4db2.
 *
 * Version: 2022-06-08 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

/**
 * Timestamp for the paging.
 */
ALTER MODULE LOGADMIN ADD
  VARIABLE PAGE_DATE ANCHOR LOGDATA.LOGS.TIMESTAMP@

/**
 * Deletes a value in the loggers cache.
 *
 * PRE
 *   No preconditions.
 * POS
 *   If the cache is active, it has been deleted after the execution.
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
 P_DELETE_CACHE: BEGIN
  SET LOGGERS_ID_CACHE = ARRAY_DELETE(LOGGERS_ID_CACHE, LOGGER);
 END P_DELETE_CACHE @

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
 P_SHOW_CONF: BEGIN
  -- Creates the cursor for the configuration freshness.
  BEGIN
   DECLARE SECS SMALLINT;
   DECLARE STMT VARCHAR(512);
   DECLARE REF CURSOR
     WITH RETURN TO CALLER
     FOR RS;
   -- Sets the value for the seconds.
   BEGIN
    DECLARE CONTINUE HANDLER FOR ARRAY_ERROR
      SET SECS = -1;
    SET SECS = INT(CONF_CACHE[REFRESH_CONS]);
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
     FROM UNNEST(CONF_CACHE) AS T(KEY, VALUE);
   DECLARE NOTHING CURSOR
     WITH RETURN TO CLIENT
     FOR
     SELECT 'Configuration not loaded' AS MESSAGE
     FROM SYSIBM.SYSDUMMY1;

   -- Checks if the configuration was already loaded.
   SET CARD = CARDINALITY(CONF_CACHE);
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
 P_SHOW_CACHE: BEGIN
  DECLARE STMT VARCHAR(512);
  DECLARE CACHE_CURSOR CURSOR
    WITH RETURN TO CLIENT
    FOR
    SELECT SUBSTR(T.LOGGER, 1, 64) AS LOGGER_NAME, T.ID AS LOGGER_ID
    FROM UNNEST(LOGGERS_ID_CACHE) AS T(LOGGER, ID);
  DECLARE DESC_CURSOR CURSOR
    WITH RETURN TO CALLER
    FOR RS;
  SET STMT = 'SELECT ''Cardinality: '
    || COALESCE(CARDINALITY(LOGGERS_ID_CACHE), -1) || ''' Value '
    || 'FROM SYSIBM.SYSDUMMY1';
  PREPARE RS FROM STMT;
  OPEN DESC_CURSOR;
  OPEN CACHE_CURSOR;
 END P_SHOW_CACHE @

/**
 * Returns an opened cursor with the level names and complete logger names of
 * the used loggers that are registered in the conf_loggers_effective table.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE SHOW_LOGGERS (
  )
  LANGUAGE SQL
  SPECIFIC P_SHOW_LOGGERS
  DYNAMIC RESULT SETS 1
  READS SQL DATA
  NOT DETERMINISTIC -- Could be deterministic if conf logger is not deleted.
  NO EXTERNAL ACTION
 P_SHOW_LOGGERS: BEGIN
  DECLARE C CURSOR
    WITH RETURN TO CLIENT
    FOR
    SELECT L.NAME AS LEVEL, LOGGER.GET_LOGGER_NAME(LOGGER_ID) AS NAME
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE E,
    LOGDATA.LEVELS L
    WHERE E.LEVEL_ID = L.LEVEL_ID
    ORDER BY LOGGER_ID
    WITH UR;

  OPEN C;
 END P_SHOW_LOGGERS @

/**
 * Returns an opened cursor showing the log messages truncated to 72 characters
 * by default, the date limited to the hour part with milliseconds, and just the
 * last 100 (by default) log messages registered. The concurrence is uncommitted
 * read. This procedure is useful to be called with named parameter, for
 * example: CALL LOGS (QTY => 50).
 *
 * IN LENGTH
 *   Message length. By default this value is 72 characters.
 * IN QTY
 *   Quantity of messages to return in the cursor.
 * IN MIN_LEVEL
 *   Minimum level presented. If -1, only internal logging is presented.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE LOGS (
  IN LENGTH SMALLINT DEFAULT 72,
  IN QTY INT DEFAULT 100,
  IN MIN_LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID DEFAULT NULL
  )
  LANGUAGE SQL
  SPECIFIC P_LOGS
  DYNAMIC RESULT SETS 1
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
 P_LOGS: BEGIN
  DECLARE STMT ANCHOR LOGGER.MESSAGE;
  DECLARE C CURSOR
    WITH RETURN TO CALLER
    FOR RS;

  SET STMT = 'SELECT TIME, MESSAGE FROM ('
    || 'SELECT TIMESTAMP AS TIME, '
    || 'SUBSTR(L.MESSAGE, 1, ' || LENGTH || ') AS MESSAGE '
    || 'FROM LOGDATA.LOGS AS L ';
  IF (MIN_LEVEL = -1) THEN
   SET STMT = STMT
     || 'WHERE L.LEVEL_ID = -1 OR L.LEVEL_ID IS NULL ';
  ELSEIF (MIN_LEVEL IS NOT NULL) THEN
   SET STMT = STMT
     || 'WHERE L.LEVEL_ID <= ' || MIN_LEVEL || ' '
     || 'AND L.LEVEL_ID >= 0 ';
  END IF;
  SET STMT = STMT
    || 'FETCH FIRST ' || QTY || ' ROWS ONLY '
    || 'WITH UR '
    || ') ORDER BY TIME DESC'
    ;
  IF (LOGGER.GET_VALUE(LOGGER.LOG_INTERNALS) = LOGGER.VAL_TRUE) THEN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
     (4, -1, 'Statement: ' || COALESCE(STMT,'NULL'));
   COMMIT;
  END IF;
  PREPARE RS FROM STMT;
  OPEN C;
 END P_LOGS @

/**
 * Returns an opened cursor showing the more recent log messages truncated to 72
 * characters by default and the date limited to the hour part with
 * milliseconds. The concurrence is uncommitted read. This procedure is useful
 * to see the progress of the generated logs.
 *
 * IN LENGTH
 *   Message length. By default this value is 72 characters.
 * IN MIN_LEVEL
 *   Minimum level presented. If -1, only internal logging is presented.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE NEXT_LOGS (
  IN LENGTH SMALLINT DEFAULT 72,
  IN MIN_LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID DEFAULT NULL
  )
  LANGUAGE SQL
  SPECIFIC P_NEXT_LOGS
  DYNAMIC RESULT SETS 1
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
 P_NEXT_LOGS: BEGIN
  DECLARE NEXT_DATE ANCHOR LOGDATA.LOGS.TIMESTAMP;
  DECLARE STMT VARCHAR(512);
  DECLARE C CURSOR
    WITH RETURN TO CALLER
    FOR RS;

  -- This query could be expensive when there is a lot of data.
  SET NEXT_DATE = (SELECT MAX(TIMESTAMP) FROM LOGDATA.LOGS);

  -- Shows the max date
  -- Debug purposes
  --CALL SYSIBMADM.DBMS_OUTPUT.PUT_LINE('Max time: ' || NEXT_DATE);

  SET STMT = 'SELECT TIME, MESSAGE FROM ('
    || 'SELECT L.TIMESTAMP AS TIME, '
    || 'SUBSTR(L.MESSAGE, 1, ' || LENGTH || ') AS MESSAGE '
    || 'FROM LOGDATA.LOGS AS L ';
  IF (MIN_LEVEL = -1) THEN
   SET STMT = STMT
     || 'WHERE L.LEVEL_ID = -1 OR L.LEVEL_ID IS NULL ';
  ELSEIF (MIN_LEVEL IS NOT NULL) THEN
   SET STMT = STMT
     || 'WHERE L.LEVEL_ID <= ' || MIN_LEVEL || ' '
     || 'AND L.LEVEL_ID >= 0 ';
  END IF;
  IF (LOGADMIN.PAGE_DATE IS NOT NULL) THEN
   IF (MIN_LEVEL IS NULL) THEN
    SET STMT = STMT
      || 'WHERE ';
   ELSE
    SET STMT = STMT
      || 'AND ';
   END IF;
   SET STMT = STMT
     || 'L.TIMESTAMP > ''' || LOGADMIN.PAGE_DATE || ''' ';
  END IF;
  SET STMT = STMT
    || 'WITH UR '
    || ') ORDER BY TIME'
    ;
  IF (LOGGER.GET_VALUE(LOGGER.LOG_INTERNALS) = LOGGER.VAL_TRUE) THEN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
     (4, -1, 'Statement: ' || COALESCE(STMT,'NULL'));
   COMMIT;
  END IF;

  -- Ddebug purposes.
  --CALL SYSIBMADM.DBMS_OUTPUT.PUT_LINE('Statement: ' || STMT);

  SET LOGADMIN.PAGE_DATE = NEXT_DATE;
  PREPARE RS FROM STMT;

  OPEN C;
 END P_NEXT_LOGS @

/**
 * Register a logger with a given level.
 *
 * IN NAME
 *   Name of the logger. This string has to be separated by dots to
 *   differentiate the levels. e.g.: foo.bar.toto, where foo is the first level,
 *   bar is the second and toto is the last one.
 *   The name could have a maximum of 256 characters, representing just one
 *   level, or several levels with short names.
 * IN LEVEL
 *   Log level to be assigned.
 * PRE
 *   No preconditions.
 * POS
 *   If the given name is valid, and if the logger does not exist, a new logger
 *   is created in the CONF_LOGGERS table; if the logger exist, its ID is
 *   returned. Finally, the given level is associated with the logger.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE REGISTER_LOGGER (
  IN NAME ANCHOR LOGGER.COMPLETE_LOGGER_NAME,
  IN LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID
  )
  LANGUAGE SQL
  SPECIFIC P_REGISTER_LOGGER
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
 P_REGISTER_LOGGER: BEGIN
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;

  CALL LOGGER.GET_LOGGER(NAME, LOGGER);
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = LEVEL
    WHERE LOGGER_ID = LOGGER;
END P_REGISTER_LOGGER @

/**
 * Register a logger with a given level name.
 *
 * IN LOGGER_NAME
 *   Name of the logger. This string has to be separated by dots to
 *   differentiate the levels. e.g.: foo.bar.toto, where foo is the first level,
 *   bar is the second and toto is the last one.
 *   The name could have a maximum of 256 characters, representing just one
 *   level, or several levels with short names.
 * IN LEVEL_NAME
 *   Name of de log level to be assigned.
 * PRE
 *   No preconditions.
 * POS
 *   If the given name is valid, and if the logger does not exist, a new logger
 *   is created in the CONF_LOGGERS table; if the logger exist, its ID is
 *   returned. Finally, the given level is associated with the logger.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE REGISTER_LOGGER_NAME (
  IN LOGGER_NAME ANCHOR LOGGER.COMPLETE_LOGGER_NAME,
  IN LEVEL_NAME ANCHOR LOGDATA.LEVELS.NAME
  )
  LANGUAGE SQL
  SPECIFIC P_REGISTER_LOGGER_NAME
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
 P_REGISTER_LOGGER_NAME: BEGIN
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE LVL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID;

  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER);
  SET LVL_ID = (SELECT LEVEL_ID FROM LOGDATA.LEVELS WHERE NAME = LEVEL_NAME);
  IF (LVL_ID IS NULL) THEN
   SIGNAL SQLSTATE VALUE 'LG0L6'
    SET MESSAGE_TEXT = 'The given logger name has not been found' ;
  END IF;
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = LVL_ID
    WHERE LOGGER_ID = LOGGER;
END P_REGISTER_LOGGER_NAME @

/**
 * Delete all loggers from CONF_LOGGERS and CONF_LOGGERS_EFFECTIVE, and resets
 * the value of the LOGGER_ID.
 * Global configuration:
 * * autonomousLogging: Write in LOGS table with an autonomous procedure.
 * * defaultRootLevelId: Default ROOT logger when it is not defined (not cached)
 * * internalCache: Use internal cache instead of SELECT for each time.
 * * logInternals: Logs internal messages.
 * * secondsToRefresh: Quantity of second before refresh the conf.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE DELETE_LOGGERS (
  )
  LANGUAGE SQL
  SPECIFIC P_DELETE_LOGGERS
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
 P_DELETE_LOGGERS: BEGIN
  DECLARE STMT VARCHAR(128);
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
  DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE WHERE LOGGER_ID <> 0;
  SET STMT = 'ALTER TABLE LOGDATA.CONF_LOGGERS ALTER COLUMN LOGGER_ID RESTART ';
  EXECUTE IMMEDIATE STMT;
 END P_DELETE_LOGGERS @

/**
 * Cleans tables.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE CLEAN_TABLES (
  )
  LANGUAGE SQL
  SPECIFIC P_CLEAN_TABLES
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
 P_CLEAN_TABLES: BEGIN
  DECLARE LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID;
  DECLARE AT_END BOOLEAN; -- End of the cursor.
  DECLARE CLEVELS CURSOR FOR
    SELECT LEVEL_ID
    FROM LOGDATA.LEVELS L
    WHERE LEVEL_ID <> 0
    ORDER BY LEVEL_ID DESC
    FOR UPDATE;
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET AT_END = TRUE;

  DELETE FROM LOGDATA.LOGS;
  DELETE FROM LOGDATA.REFERENCES;
  DELETE FROM LOGDATA.CONF_APPENDERS;
  DELETE FROM LOGDATA.APPENDERS;
  UPDATE LOGDATA.CONF_LOGGERS SET LEVEL_ID = 0 WHERE LOGGER_ID = 0;
  CALL DELETE_LOGGERS();
  COMMIT;

  OPEN CLEVELS;
  SET AT_END = FALSE;
  FETCH CLEVELS INTO LEVEL_ID;
  WHILE (AT_END = FALSE) DO
   DELETE FROM LOGDATA.LEVELS WHERE CURRENT OF CLEVELS;
   FETCH CLEVELS INTO LEVEL_ID;
  END WHILE;

  DELETE FROM LOGDATA.CONFIGURATION;
 END P_CLEAN_TABLES @

/**
 * Cleans tables.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE POPULATE_TABLES (
  )
  LANGUAGE SQL
  SPECIFIC P_POPULATE_TABLES
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
 P_POPULATE_TABLES: BEGIN
  DECLARE MAX ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;

  INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE)
    VALUES ('autonomousLogging', 'true'),
           ('defaultRootLevelId', '3'),
           ('internalCache', 'true'),
           ('logInternals', 'false'),
           ('secondsToRefresh', '30');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME)
    VALUES (1, 'fatal');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME)
    VALUES (2, 'error');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME)
    VALUES (3, 'warn');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME)
    VALUES (4, 'info');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME)
    VALUES (5, 'debug');
  -- Root logger by default is warn.
  UPDATE LOGDATA.CONF_LOGGERS SET LEVEL_ID = 3 WHERE LOGGER_ID = 0;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME)
  VALUES (0, 'Null'),
         (1, 'Tables');
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION,
    PATTERN)
    VALUES ('Null', 0, NULL, NULL),
           ('Tables', 1, NULL, '[%p] %c -%T%m');
  SET MAX = (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS);
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, MAX);
 END P_POPULATE_TABLES @

/**
 * Deletes the content of all tables in this utility.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE RESET_TABLES (
  )
  LANGUAGE SQL
  SPECIFIC P_RESET_TABLES
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
 P_RESET_TABLES: BEGIN
  CALL CLEAN_TABLES();
  CALL POPULATE_TABLES;
 END P_RESET_TABLES @

-- Insert the values on all tables.
CALL LOGADMIN.RESET_TABLES()@

/**
 * Shows the license of this utility.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE LICENSE (
  )
  LANGUAGE SQL
  SPECIFIC P_LICENSE
  DYNAMIC RESULT SETS 1
  READS SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
 P_LICENSE: BEGIN
  DECLARE LICENSE_CURSOR CURSOR
    WITH RETURN FOR
    SELECT LINE
    FROM LOGDATA.LICENSE
    ORDER BY NUMBER;
  OPEN LICENSE_CURSOR;
 END P_LICENSE @

--#SET TERMINATOR ;
-- Runstats on all tables.
RUNSTATS ON TABLE LOGDATA.CONFIGURATION ON ALL COLUMNS AND INDEXES ALL;
RUNSTATS ON TABLE LOGDATA.LEVELS ON ALL COLUMNS AND INDEXES ALL;
RUNSTATS ON TABLE LOGDATA.CONF_LOGGERS ON ALL COLUMNS AND INDEXES ALL;
RUNSTATS ON TABLE LOGDATA.CONF_LOGGERS_EFFECTIVE ON ALL COLUMNS AND INDEXES ALL;
RUNSTATS ON TABLE LOGDATA.APPENDERS ON ALL COLUMNS AND INDEXES ALL;
RUNSTATS ON TABLE LOGDATA.CONF_APPENDERS ON ALL COLUMNS AND INDEXES ALL;
RUNSTATS ON TABLE LOGDATA.REFERENCES ON ALL COLUMNS AND INDEXES ALL;

