--#SET TERMINATOR @
SET CURRENT SCHEMA LOGGER @

/**
 * Writes the given message in the log table. This is a pure SQL implementation,
 * without any external call.
 *
 * IN LOGGER_ID
 *   Identification of the associated logger.
 * IN LEVEL_ID
 *   Identification of the associates level.
 * IN MESSAGE
 *   Descriptive message to write in the log table.
 * IN CONFIGURATION
 *   Any particular configuration for the logger (TODO currently not used.) 
 */
ALTER MODULE LOGGER ADD 
  PROCEDURE LOG_SQL (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE,
  IN CONFIGURATION ANCHOR CONF_APPENDERS.CONFIGURATION
  )
  LANGUAGE SQL
  SPECIFIC P_LOG_SQL
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  DETERMINISTIC -- With the same parameters, it will always do the same.
  AUTONOMOUS
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_LOG_SQL: BEGIN
  INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, ENVIRONMENT, MESSAGE) VALUES
    (LEVEL_ID, LOGGER_ID, CURRENT USER, MESSAGE);
  COMMIT;
 END P_LOG_SQL @

/**
 * TODO Writes the provided message in the db2diag.log file (DIAGPATH) via
 * db2AdminMsgWrite.
 *
 * IN LOGGER_ID
 *   Identification of the associated logger.
 * IN LEVEL_ID
 *   Identification of the associates level.
 * IN MESSAGE
 *   Descriptive message to write in the log table.
 * IN CONFIGURATION
 *   TODO Any particular configuration for the logger. 
 */
ALTER MODULE LOGGER PUBLISH 
  PROCEDURE LOG_DB2DIAG (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE,
  IN CONFIGURATION ANCHOR CONF_APPENDERS.CONFIGURATION
  ) @

/**
 * TODO Writes the provided message in a file via UTL_FILE built-in functions.
 * This appender cannot be used in Express-C edition due to restrictions of
 * the built-in modules in this edition.
 * The implementation could retrieve the filename from a global variable, and
 * keep the handler there, in order to reduce the overhead by opening and
 * closing the file for each call.
 *
 * IN LOGGER_ID
 *   Identification of the associated logger.
 * IN LEVEL_ID
 *   Identification of the associates level.
 * IN MESSAGE
 *   Descriptive message to write in the log table.
 * IN CONFIGURATION
 *   TODO Any particular configuration for the logger. 
 */
ALTER MODULE LOGGER PUBLISH 
  PROCEDURE LOG_UTL_FILE (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE,
  IN CONFIGURATION ANCHOR CONF_APPENDERS.CONFIGURATION
  ) @

/**
 * TODO Writes the provided message in the DB2LOGGER. This is an external logging
 * facility implemented in C, and that has only two levels for loggers.
 *
 * IN LOGGER_ID
 *   Identification of the associated logger.
 * IN LEVEL_ID
 *   Identification of the associates level.
 * IN MESSAGE
 *   Descriptive message to write in the log table.
 * IN CONFIGURATION
 *   TODO Any particular configuration for the logger. 
 */
ALTER MODULE LOGGER PUBLISH 
  PROCEDURE LOG_DB2LOGGER (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE,
  IN CONFIGURATION ANCHOR CONF_APPENDERS.CONFIGURATION
  ) @

/**
 * TODO Writes the provided message in the Java configured facility. This
 * logger could use log4j or slf4j/logback as back-end, it depends on the Java
 * implementation.
 *
 * IN LOGGER_ID
 *   Identification of the associated logger.
 * IN LEVEL_ID
 *   Identification of the associates level.
 * IN MESSAGE
 *   Descriptive message to write in the log table.
 * IN CONFIGURATION
 *   TODO Any particular configuration for the logger. 
 */
ALTER MODULE LOGGER PUBLISH 
  PROCEDURE LOG_JAVA (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE,
  IN CONFIGURATION ANCHOR CONF_APPENDERS.CONFIGURATION
  ) @

/**
 * Sends a message into the logger system. Before to log this message in an
 * appender, this method verifies the logger level given if it is superior or
 * or equal to the configured level. If not, it skips this process.
 * After validating the level, it checks all appenders to see in which it has to
 * log the message.
 *
 * IN LOGGER_ID
 *   This is the associated logger of the provided message. Default logger is
 *   ROOT, that is 0.
 * IN LEVEL_ID
 *   Level of the message. Default level is 3, which is WARN.
 * IN MESSAGE
 *   Message to log.
 */
ALTER MODULE LOGGER ADD 
  PROCEDURE LOG (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID DEFAULT 0,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID DEFAULT 3,
  IN MESSAGE ANCHOR LOGS.MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_LOG
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC -- If the configuration changes, the log could not be
                    -- written in the same way.
  AUTONOMOUS
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_LOG: BEGIN
  DECLARE CURRENT_LEVEL_ID SMALLINT; -- Level in the configuration.
  DECLARE APPENDER_ID SMALLINT; -- Appender's ID.
  DECLARE CONFIGURATION VARCHAR(256); -- Appender's configuration.
  DECLARE AT_END BOOLEAN; -- End of the cursor.
  DECLARE APPENDERS CURSOR FOR
    SELECT APPENDER_ID, CONFIGURATION
    FROM CONF_APPENDERS;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '55019'
    INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, ENVIRONMENT, MESSAGE) VALUES 
    (3, 0, CURRENT USER, 'Appender not available');
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET AT_END = TRUE;

  -- Retrieves the current level in the configuration for the given logger.
  SELECT C.LEVEL_ID INTO CURRENT_LEVEL_ID 
    FROM CONF_LOGGERS_EFFECTIVE C
    WHERE C.LOGGER_ID = LOGGER_ID
    FETCH FIRST 1 ROW ONLY;

  -- Checks if the current level is at least equal to the provided level.
  -- TODO Verificar esto, ya que aquí se puede usar la tabla references, si root
  -- no está activo.
  IF (CURRENT_LEVEL_ID >= LEVEL_ID) THEN
   -- TODO Format the message according to the pattern.
   -- SYSPROC.MON_GET_APPLICATION_ID()
   -- Retrieves all the configurations for the appenders.
   OPEN APPENDERS;
   SET AT_END = FALSE;
   FETCH APPENDERS INTO APPENDER_ID, CONFIGURATION;
   -- Iterates over the results.
   WHILE (AT_END = FALSE) DO
    -- Checks the values
    CASE APPENDER_ID
      WHEN 1 THEN -- Pure SQL PL, writes in table.
        CALL LOG_SQL(LOGGER_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
      WHEN 2 THEN -- Writes in the db2diag.log file via a function.
        CALL LOG_DB2DIAG(LOGGER_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
      WHEN 3 THEN -- Writes in a file (Not available in express-c edition.)
        CALL LOG_UTL_FILE(LOGGER_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
      WHEN 4 THEN -- Sends the log to the DB2LOGGER in C.
        CALL LOG_DB2LOGGER(LOGGER_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
      WHEN 5 THEN -- Sends the log to Java, and takes the configuration there.
        CALL LOG_JAVA(LOGGER_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
      ELSE -- By default writes in the table.
        CALL LOG_SQL(LOGGER_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
    END CASE;
    FETCH APPENDERS INTO APPENDER_ID, CONFIGURATION;
   END WHILE;
   CLOSE APPENDERS;
  END IF;
END P_LOG @

/**
 * Logs a message at debug (5) level.
 *
 * IN LOGGER_ID
 *   This is the associated logger of the provided message.
 * IN MESSAGE
 *   Message to log.
 */
ALTER MODULE LOGGER ADD 
  PROCEDURE DEBUG (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID DEFAULT 0,
  IN MESSAGE ANCHOR LOGS.MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_DEBUG
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_DEBUG: BEGIN
  CALL LOG (LOGGER_ID, 5, MESSAGE);
 END P_DEBUG @

/**
 * Logs a message at info (4) level.
 *
 * IN LOGGER_ID
 *   This is the associated logger of the provided message.
 * IN MESSAGE
 *   Message to log.
 */
ALTER MODULE LOGGER ADD 
  PROCEDURE INFO (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID DEFAULT 0,
  IN MESSAGE ANCHOR LOGS.MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_INFO
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_INFO: BEGIN
  CALL LOG (LOGGER_ID, 4, MESSAGE);
 END P_INFO @

/**
 * Logs a message at warn (3) level.
 *
 * IN LOGGER_ID
 *   This is the associated logger of the provided message.
 * IN MESSAGE
 *   Message to log.
 */
ALTER MODULE LOGGER ADD 
  PROCEDURE WARN (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID DEFAULT 0,
  IN MESSAGE ANCHOR LOGS.MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_WARN
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_WARN: BEGIN
  CALL LOG (LOGGER_ID, 3, MESSAGE);
 END P_WARN @

/**
 * Logs a message at error (2) level.
 *
 * IN LOGGER_ID
 *   This is the associated logger of the provided message.
 * IN MESSAGE
 *   Message to log.
 */
ALTER MODULE LOGGER ADD 
  PROCEDURE ERROR (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID DEFAULT 0,
  IN MESSAGE ANCHOR LOGS.MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_ERROR
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ERROR: BEGIN
  CALL LOG (LOGGER_ID, 2, MESSAGE);
 END P_ERROR @

/**
 * Logs a message at fatal (1) level.
 *
 * IN LOGGER_ID
 *   This is the associated logger of the provided message.
 * IN MESSAGE
 *   Message to log.
 */
ALTER MODULE LOGGER ADD 
  PROCEDURE FATAL (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID DEFAULT 0,
  IN MESSAGE ANCHOR LOGS.MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_FATAL
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_FATAL: BEGIN
  CALL LOG (LOGGER_ID, 1, MESSAGE);
 END P_FATAL @