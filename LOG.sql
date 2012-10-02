--#SET TERMINATOR @
SET CURRENT SCHEMA LOGGER @

SET PATH = SYSPROC, LOGGER @

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
 */
ALTER MODULE LOGGER ADD 
  PROCEDURE LOG_SQL (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE
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
  INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
    (LEVEL_ID, LOGGER_ID, MESSAGE);
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
 * Retrieves the complete logger name for a given logged id.
 *
 * IN LOGGER_ID
 *  Identification of the logger in the effective table.
 * RETURNS the complete name of the logger (recursive.)
 */
ALTER MODULE LOGGER ADD
 FUNCTION GET_LOGGER_NAME (
  IN LOG_ID ANCHOR CONF_LOGGERS.LOGGER_ID
  ) RETURNS VARCHAR(256)
  LANGUAGE SQL
  PARAMETER CCSID UNICODE
  SPECIFIC F_GET_NAME
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  READS SQL DATA
  SECURED
 F_GET_NAME: BEGIN
  DECLARE COMPLETE_NAME VARCHAR(256);
  DECLARE PARENT ANCHOR CONF_LOGGERS.LOGGER_ID;
  DECLARE NAME ANCHOR CONF_LOGGERS.NAME;
  DECLARE RETURNED VARCHAR(256);
  
  -- The logger is ROOT.
  IF (LOG_ID = 0) THEN
   SET COMPLETE_NAME = 'ROOT';
  ELSE
   -- Retrieves the id of the parent logger.
   SELECT E.PARENT_ID, E.NAME INTO PARENT, NAME
     FROM CONF_LOGGERS_EFFECTIVE E
     WHERE E.LOGGER_ID = LOG_ID;

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
 * Parses the provided message according to the defined pattern. It replaces
 * the occurences of every conversion word with the corresponding value.
 * In the next table, the possible replacements are described:
 * 
 * +-----------------+---------------------------------------------------------+
 * | Conversion Word | Effect                                                  |
 * +-----------------+---------------------------------------------------------+
 * | p               | Inserts the level of the logging event.                 |
 * +-----------------+---------------------------------------------------------+
 * | c               | Inserts the name of the logger at the origin of the     |
 * |                 | logging event.                                          |
 * +-----------------+---------------------------------------------------------+
 * | m               | Inserts the application-supplied message associated     |
 * |                 | with the logging event.                                 |
 * +-----------------+---------------------------------------------------------+
 * | H               | Inserts the application handle.                         |
 * +-----------------+---------------------------------------------------------+
 * | N               | Inserts the application name.                           |
 * +-----------------+---------------------------------------------------------+
 * | I               | Inserts the application id.                             |
 * +-----------------+---------------------------------------------------------+
 * | S               | Inserts the session authorisation.                      |
 * +-----------------+---------------------------------------------------------+
 * | C               | Inserts the client hostname.                            |
 * +-----------------+---------------------------------------------------------+
 * 
 * All this conversion words should be preceded by the % (percentage) sign.
 * The environment information is retreived via table and scalar functions
 * included in DB2.
 *
 * IN PATTERN
 *   String that contains the pattern to parse the message.
 * IN LOG_ID
 *   ID of the associated logger.
 * IN LEV_ID
 *   ID of the associated level.
 * INOUT MESSAGE
 *   Message to log.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE PARSE_MESSAGE (
  IN PATTERN ANCHOR CONF_APPENDERS.PATTERN, 
  IN LOG_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN LEV_ID ANCHOR LEVELS.LEVEL_ID,
  INOUT MESSAGE ANCHOR LOGS.MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_PARSE_MESSAGE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_PARSE: BEGIN
  DECLARE NEW_MESSAGE ANCHOR LOGS.MESSAGE;
  DECLARE LEVEL_NAME ANCHOR LEVELS.NAME;

  SET NEW_MESSAGE = PATTERN;
  -- Inserts the level.
  SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%p', (
    SELECT UCASE(COALESCE(NAME,'UNK')) 
    FROM LEVELS
    WHERE LEVEL_ID = LEV_ID));
  
  -- Inserts the logger name.
  SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%c', COALESCE(GET_LOGGER_NAME(LOG_ID), 'No name'));
  
  -- Inserts the message.
  SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%m', COALESCE(MESSAGE,'No message'));
  
  -- Inserts the application handle.
  SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%H', 
    SYSPROC.MON_GET_APPLICATION_HANDLE());
  
  -- Inserts the application name.
  SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%N',
    (SELECT APPLICATION_NAME
    FROM TABLE(MON_GET_CONNECTION(SYSPROC.MON_GET_APPLICATION_HANDLE(),-1))));

  -- Inserts the application id.
  SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%I', SYSPROC.MON_GET_APPLICATION_ID());

  -- Inserts the session authorisation.
  SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%S', TRIM(SESSION_USER));

  -- Inserts the client hostname.
  SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%C', CLIENT WRKSTNNAME);

  SET MESSAGE = NEW_MESSAGE;
 END P_PARSE @

/**
 * Sends a message into the logger system. Before to log this message in an
 * appender, this method verifies the logger level given if it is superior or
 * or equal to the configured level. If not, it skips this process.
 * After validating the level, it checks all appenders to see in which it has to
 * log the message.
 *
 * IN LOG_ID
 *   This is the associated logger of the provided message. Default logger is
 *   ROOT, that is 0.
 * IN LEVEL_ID
 *   Level of the message. Default level is 3, which is WARN.
 * IN MESSAGE
 *   Message to log.
 */
ALTER MODULE LOGGER ADD 
  PROCEDURE LOG (
  IN LOG_ID ANCHOR CONF_LOGGERS.LOGGER_ID DEFAULT 0,
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
  DECLARE CURRENT_LEVEL_ID ANCHOR LEVELS.LEVEL_ID; -- Level in the configuration.
  DECLARE APPENDER_ID ANCHOR CONF_APPENDERS.APPENDER_ID; -- Appender's ID.
  DECLARE CONFIGURATION ANCHOR CONF_APPENDERS.CONFIGURATION; -- Appender's configuration.
  DECLARE PATTERN ANCHOR CONF_APPENDERS.PATTERN; -- Appender's pattern. 
  DECLARE AT_END BOOLEAN; -- End of the cursor.
  DECLARE APPENDERS CURSOR FOR
    SELECT APPENDER_ID, CONFIGURATION, PATTERN
    FROM CONF_APPENDERS;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '55019'
    INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES 
    (2, -1, 'Appender not available');
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET AT_END = TRUE;

  -- Retrieves the current level in the configuration for the given logger.
  SELECT C.LEVEL_ID INTO CURRENT_LEVEL_ID 
    FROM CONF_LOGGERS_EFFECTIVE C
    WHERE C.LOGGER_ID = LOG_ID;

  -- Checks if the current level is at least equal to the provided level.
  -- TODO Verificar esto, ya que aquí se puede usar la tabla references, si root
  -- no está activo.
  IF (CURRENT_LEVEL_ID >= LEVEL_ID) THEN
   -- Internal logging.
   IF (GET_VALUE(LOGGER.LOG_INTERNALS) = LOGGER.VAL_TRUE) THEN
    INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES 
      (4, -1, 'Logging enable for level ' || LEVEL_ID || ' logger ' || LOG_ID);
   END IF;

   -- 
   -- Retrieves all the configurations for the appenders.
   OPEN APPENDERS;
   SET AT_END = FALSE;
   FETCH APPENDERS INTO APPENDER_ID, CONFIGURATION, PATTERN;
   -- Iterates over the results.
   WHILE (AT_END = FALSE) DO
    -- Format the message according to the pattern.
    CALL PARSE_MESSAGE(PATTERN, LOG_ID, LEVEL_ID, MESSAGE);
    -- Checks the values
    CASE APPENDER_ID
      WHEN 1 THEN -- Pure SQL PL, writes in table.
        CALL LOG_SQL(LOG_ID, LEVEL_ID, MESSAGE);
      WHEN 2 THEN -- Writes in the db2diag.log file via a function.
        CALL LOG_DB2DIAG(LOG_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
      WHEN 3 THEN -- Writes in a file (Not available in express-c edition.)
        CALL LOG_UTL_FILE(LOG_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
      WHEN 4 THEN -- Sends the log to the DB2LOGGER in C.
        CALL LOG_DB2LOGGER(LOG_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
      WHEN 5 THEN -- Sends the log to Java, and takes the configuration there.
        CALL LOG_JAVA(LOG_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
      ELSE -- By default writes in the table.
        CALL LOG_SQL(LOG_ID, LEVEL_ID, MESSAGE);
    END CASE;
    FETCH APPENDERS INTO APPENDER_ID, CONFIGURATION, PATTERN;
   END WHILE;
   CLOSE APPENDERS;
  ELSEIF (LOG_ID = -1) THEN
   -- When the logged id is -1, this is for internal logging.
   CALL LOG_SQL(LOG_ID, LEVEL_ID, MESSAGE);
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