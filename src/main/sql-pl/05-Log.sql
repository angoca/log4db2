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
 * Implementation of the LOG procedure. This is one of the most important and
 * longest stored procedure in the utility; for this reason it is in a
 * dedicated file.
 *
 * Version: 2014-02-14 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET PATH = SYSPROC, LOGGER_1RC @

/**
 * Verifies if the given logger hierarchy path includes the given logger id.
 * This allows to register or not the given logger according to the
 * configuration.
 *
 * IN HIERARCHY
 *   Comma separated IDs that represents the ascendency of a logger.
 * IN LOGGER_ID
 *   Logger ID to check if that is part of the hierarchy.
 * RETURNS TRUE if the logger is part of the hierarchy. Otherwise false.
 * TESTS
 *   TestsHierarchy: Verifies different output to validate if the logger is
 *   of the hierarchy.
 */
ALTER MODULE LOGGER ADD
 FUNCTION IS_LOGGER_ACTIVE (
  IN HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY,
  IN LOGGER_ID_FETCHED ANCHOR LOGDATA.REFERENCES.LOGGER_ID
  ) RETURNS BOOLEAN
  LANGUAGE SQL
  PARAMETER CCSID UNICODE
  SPECIFIC F_IS_LOGGER_ACTIVE
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  READS SQL DATA
 F_IS_LOGGER_ACTIVE: BEGIN
  DECLARE POS SMALLINT;
  DECLARE RET BOOLEAN DEFAULT FALSE;
  DECLARE CURRENT ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;

  IF (HIERARCHY = '0') THEN
   IF (LOGGER_ID_FETCHED = 0) THEN
    SET RET = TRUE;
   END IF;
  ELSE
   SET POS = POSSTR (HIERARCHY, ',');
   REPEAT
    IF (POS <> 0) THEN
     SET CURRENT = SUBSTR(HIERARCHY, 1, POS - 1);
     SET HIERARCHY = SUBSTR(HIERARCHY, POS + 1);
     SET POS = POSSTR (HIERARCHY, ',');
    ELSE
     SET CURRENT = HIERARCHY;
     SET POS = -1;
    END IF;
   -- Testing any other level.
    IF (LOGGER_ID_FETCHED = SMALLINT(CURRENT)) THEN
     SET RET = TRUE;
    END IF;
   UNTIL (RET = TRUE OR POS < 0)
   END REPEAT;
  END IF;
  RETURN RET;
 END F_IS_LOGGER_ACTIVE @

/**
 * Returns a string with the tabulation according to the given quantity of
 * levels, it means the nesting level.
 *
 * IN LEVELS
 *   Quantity of levels.
 */
ALTER MODULE LOGGER ADD
  FUNCTION GET_TABULATION (
  IN LEVELS INTEGER
  ) RETURNS ANCHOR MESSAGE
  LANGUAGE SQL
  PARAMETER CCSID UNICODE
  SPECIFIC F_GET_TABULATION
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  READS SQL DATA
 F_GET_TABULATION: BEGIN
  DECLARE INDEX SMALLINT DEFAULT 0;
  DECLARE TABULATION ANCHOR MESSAGE DEFAULT '';
  WHILE (INDEX < LEVELS) DO
   SET TABULATION = ' ' || TABULATION;
   SET INDEX = INDEX + 1;
  END WHILE;
  RETURN TABULATION;
 END F_GET_TABULATION @

/**
 * Sends a message into the logger system. Before to log this message in an
 * appender, this method verifies the logger level given if it is superior or
 * or equal to the configured level. If not, it skips this process.
 * After validating the level, it parses the message according to the pattern,
 * and then it checks all appenders to see in which it has to log the message.
 * In the next table, the possible replacements in the parsing are described:
 *
 * +-----------------+---------------------------------------------------------+
 * | Conversion Word | Effect                                                  |
 * +-----------------+---------------------------------------------------------+
 * | c               | Inserts the name of the logger at the origin of the     |
 * |                 | logging event.                                          |
 * +-----------------+---------------------------------------------------------+
 * | m               | Inserts the application-supplied message associated     |
 * |                 | with the logging event.                                 |
 * +-----------------+---------------------------------------------------------+
 * | p               | Inserts the level of the logging event.                 |
 * +-----------------+---------------------------------------------------------+
 * | C               | Inserts the client hostname.                            |
 * +-----------------+---------------------------------------------------------+
 * | H               | Inserts the application handle.                         |
 * +-----------------+---------------------------------------------------------+
 * | I               | Inserts the application id.                             |
 * +-----------------+---------------------------------------------------------+
 * | L               | Inserts the nesting level.                              |
 * +-----------------+---------------------------------------------------------+
 * | N               | Inserts the application name.                           |
 * +-----------------+---------------------------------------------------------+
 * | S               | Inserts the session authorisation.                      |
 * +-----------------+---------------------------------------------------------+
 * | T               | Tabulates the nesting level.                            |
 * +-----------------+---------------------------------------------------------+
 *
 * All this conversion words should be preceded by the % (percentage) sign.
 * The environment information is retrieved via table and scalar functions
 * included in DB2.
 *
 *
 * IN LOG_ID
 *   This is the associated logger of the provided message. Default logger is
 *   ROOT, that is 0.
 * IN LEV_ID
 *   Level of the message. Default level is 3, which is WARN.
 * IN MESSAGE
 *   Message to log.
 * PRE
 *   The LOG_ID should exists in CONF_LOGGERS table in order to associate the
 *   given message with the logger. If that does not exist or an invalid
 *   LOG_ID is given, then it is associated to ROOT logger. Some exceptions
 *   also exist.
 * POS
 *   According to the LEV_ID, the CONF_LOGGERS configuration, the
 *   CONF_APPENDERS and REFERECES, the message could be or not written in an
 *   appender.
 * TESTS
 *   TestsCascadeCallLimit: Allows to verify the quantity of levels, and to
 *   register all messages.
 *   TestsLayout: Validates the different options of the layout.
 *   TestsLogs: Validates that the messages are well written.
 *   TestsMessages: Checks the output of the error.
 *   TestsReferences: Verifies when to write, and how.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE LOG (
  IN LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID DEFAULT 0,
  IN LEV_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID DEFAULT DEFAULT_LEVEL,
  IN MESSAGE ANCHOR MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_LOG
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC -- If the configuration changes, the log could not be
                    -- written in the same way.
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_LOG: BEGIN
  -- Reserved names for errors.
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

  DECLARE NEW_MESSAGE ANCHOR MESSAGE;
  DECLARE INTERNAL BOOLEAN DEFAULT FALSE; -- Internal logging.
  DECLARE CURRENT_LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID; -- Level in the configuration.
  DECLARE REAL_LVL ANCHOR LOGDATA.LEVELS.LEVEL_ID; -- Real level if exist.
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY; -- Logger's hierarchy.
  DECLARE CURRENT_APPENDER_NAME ANCHOR LOGDATA.CONF_APPENDERS.NAME; -- Name for exception.
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.APPENDER_ID; -- Appender's ID.
  DECLARE CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION; -- Appender's configuration.
  DECLARE PATTERN ANCHOR LOGDATA.CONF_APPENDERS.PATTERN; -- Appender's pattern.
  DECLARE LVL_REF ANCHOR LOGDATA.CONF_APPENDERS.LEVEL_ID; -- Appender's level.
  DECLARE LOGGER_ID_FETCHED ANCHOR LOGDATA.REFERENCES.LOGGER_ID; -- Logger id to be analysed.
  DECLARE APPEND_NAME ANCHOR LOGDATA.APPENDERS.NAME; -- Appender's suffix name.
  DECLARE LOGGER_DATA LOGGERS_ROW; -- Data of the logger.
  DECLARE AT_END BOOLEAN; -- End of the cursor.
  DECLARE ACTIVE BOOLEAN;
  DECLARE NESTING_LEVEL INTEGER;
  DECLARE TABULATION ANCHOR MESSAGE;
  DECLARE TRUNCATED_STRING CONDITION FOR SQLSTATE '01004';
  -- FIXME: The following query cannot be cached because it has an XML column.
  DECLARE REFERENCES CURSOR WITH HOLD FOR
    SELECT LOGGER_ID, C.NAME, C.APPENDER_ID, CONFIGURATION, PATTERN, LEVEL_ID,
    A.NAME
    FROM LOGDATA.REFERENCES R JOIN LOGDATA.CONF_APPENDERS C
    ON R.APPENDER_REF_ID = C.REF_ID
    JOIN LOGDATA.APPENDERS A
    ON C.APPENDER_ID = A.APPENDER_ID
    -- 5 active appenders is already too much.
    OPTIMIZE FOR 5 ROW
    WITH UR; -- <<< db2diag
  -- Ignore warning when the value has been truncate.
  DECLARE CONTINUE HANDLER FOR TRUNCATED_STRING
    BEGIN
    END;
  -- Log any other warning.
  DECLARE CONTINUE HANDLER FOR SQLWARNING
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE)
    VALUES (4, 'Appender ' || TRIM(COALESCE(CURRENT_APPENDER_NAME, 'No name'))
    || ':-Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE
    || '=' || COALESCE(MESSAGE,'No message'));
  -- Log any exception.
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE)
    VALUES (4, 'Appender ' || TRIM(COALESCE(CURRENT_APPENDER_NAME, 'No name'))
    || ':-Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE
    || '=' || COALESCE(MESSAGE,'No message'));
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET AT_END = TRUE;
  -- Handles the limit cascade call.
  DECLARE EXIT HANDLER FOR NESTED_LIMIT_ACHIEVED
   BEGIN
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES
    (2, 'LG001. Cascade call limit achieved, for LOG: '
      || COALESCE(MESSAGE, 'null'));
    RESIGNAL SQLSTATE 'LG001'
      SET MESSAGE_TEXT = 'Cascade call limit achieved. Log message was written';
   END;

  -- Internal logging.
  IF (GET_VALUE(LOG_INTERNALS) = VAL_TRUE) THEN
   SET INTERNAL = TRUE;
  END IF;

  -- The given logger is invalid
  IF (LOG_ID IS NULL OR LOG_ID < -1) THEN
   SET LOG_ID = 0;
  END IF;
  -- The given level is null, then level 1.
  IF (LEV_ID IS NULL OR LEV_ID < 0) THEN
   SET LEV_ID = DEFAULT_LEVEL;
  ELSE
   BEGIN
    DECLARE VAL BOOLEAN;
    SET VAL = EXIST_LEVEL(LEV_ID);
    IF (VAL = FALSE) THEN
     SET LEV_ID = DEFAULT_LEVEL;
    END IF;
   END;
  END IF;

  -- Retrieves the current level in the configuration for the given logger.
  SET LOGGER_DATA = GET_LOGGER_DATA(LOG_ID); -- <<< db2diag
  SET CURRENT_LEVEL_ID = LOGGER_DATA.LEVEL_ID;
  SET HIERARCHY = LOGGER_DATA.HIERARCHY;

  -- LOG_ID could not exist
  IF (CURRENT_LEVEL_ID IS NULL) THEN
   SET CURRENT_LEVEL_ID = DEFAULT_LEVEL;
   SET HIERARCHY = '0';
  END IF;
  -- Checks if the current level is at least equal to the provided level.
  IF (CURRENT_LEVEL_ID >= LEV_ID AND LEV_ID > 0) THEN
   -- Internal logging.
   IF (INTERNAL = TRUE) THEN
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
      (4, -1, 'Logging enable for level ' || LEV_ID || ' logger ' || LOG_ID);
   END IF;

   -- Retrieves all the configurations for the appenders in references table.
   OPEN REFERENCES;
   SET AT_END = FALSE;
   FETCH REFERENCES INTO LOGGER_ID_FETCHED, CURRENT_APPENDER_NAME, APPENDER_ID,
     CONFIGURATION, PATTERN, LVL_REF, APPEND_NAME;

   -- Iterates over the results.
   WHILE (AT_END = FALSE) DO
    SET ACTIVE = IS_LOGGER_ACTIVE(HIERARCHY, LOGGER_ID_FETCHED);
   -- Internal logging.
    IF (INTERNAL = TRUE) THEN
     INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
       (4, -1, 'Active logger ' || LOGGER_ID_FETCHED || ' value '
       || BOOL_TO_CHAR(ACTIVE));
    END IF;
    -- Checks if the appender should receive this log.
    IF (ACTIVE = TRUE) THEN
     IF (LVL_REF IS NOT NULL AND LEV_ID > LVL_REF) THEN
      SET ACTIVE = FALSE;
     END IF;
    END IF;
    IF (ACTIVE = TRUE) THEN
     -- Internal logging.
     IF (INTERNAL = TRUE) THEN
      INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
        (4, -1, 'Processing pattern ' || PATTERN);
     END IF;

     -- Format the message according to the pattern.
     SET NEW_MESSAGE = PATTERN;
     -- Inserts the level.
     SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%p', (
       COALESCE(UCASE(GET_LEVEL_NAME(LEV_ID)), 'UNK')));
     -- Inserts the application handle.
     SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%H',
       SYSPROC.MON_GET_APPLICATION_HANDLE());
     -- Inserts the application name.
     SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%N',
       (SELECT APPLICATION_NAME
       FROM TABLE(MON_GET_CONNECTION(SYSPROC.MON_GET_APPLICATION_HANDLE(), -1))
       FETCH FIRST 1 ROW ONLY
       WITH UR
       ));
     -- Inserts the application id.
     SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%I',
       SYSPROC.MON_GET_APPLICATION_ID());
     -- Inserts the session authorisation.
     SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%S', TRIM(SESSION_USER));
     -- Inserts the client hostname.
     SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%C', CLIENT WRKSTNNAME);
     -- Insert the nesting level.
     GET DIAGNOSTICS NESTING_LEVEL = DB2_SQL_NESTING_LEVEL;
     SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%L', NESTING_LEVEL);
     -- Tabulates according to the nesting level.
     SET TABULATION = GET_TABULATION(NESTING_LEVEL);
     SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%T', TABULATION);
     -- Inserts the logger name.
     SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%c',
       COALESCE(GET_LOGGER_NAME(LOG_ID), 'No name'));
     -- Inserts the message.
     SET NEW_MESSAGE = REPLACE(NEW_MESSAGE, '%m',
       COALESCE(MESSAGE, 'No message'));

     -- Checks the values
     CASE APPENDER_ID
       WHEN 1 THEN -- Pure SQL PL, writes in table.
        -- Internal logging.
        IF (INTERNAL = TRUE) THEN
         INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
           (4, -1, 'Logging in tables');
        END IF;
        IF (GET_VALUE(AUTONOMOUS_LOGGING) = VAL_TRUE) THEN
         CALL LOG_TABLES_AUTONOMOUS(LOG_ID, LEV_ID, NEW_MESSAGE);
        ELSE
         CALL LOG_TABLES(LOG_ID, LEV_ID, NEW_MESSAGE);
        END IF;
       WHEN 0 THEN -- Drops the message.
        CALL LOG_NULL(LOG_ID, LEV_ID, NEW_MESSAGE, CONFIGURATION);
       ELSE -- Execute any other appender.
        DYNAMIC : BEGIN
         DECLARE CALL VARCHAR(64);
         DECLARE CONT BOOLEAN DEFAULT TRUE;
         DECLARE UNAVALIBLE_APPENDER CONDITION FOR SQLSTATE '55019';
         DECLARE INEXISTANT_APPENDER CONDITION FOR SQLSTATE '42884';
         DECLARE STMT STATEMENT;
         DECLARE CONTINUE HANDLER FOR UNAVALIBLE_APPENDER
           INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
           (2, -1, 'Appender not available: ' || TRIM(COALESCE(
           CURRENT_APPENDER_NAME, 'No name')) || '=' || NEW_MESSAGE);

         -- Using non-existent appender.
         DECLARE CONTINUE HANDLER FOR INEXISTANT_APPENDER
           BEGIN
            INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
            (2, -1, 'Non-existent appender: '
            || TRIM(COALESCE(CURRENT_APPENDER_NAME, 'No name')) || '='
            || COALESCE(NEW_MESSAGE,'No message'));
            SET CONT = FALSE;
           END;
         SET CALL = 'CALL LOG_' || APPEND_NAME || '(?, ?, ?, ?)';
         -- Internal logging.
         IF (INTERNAL = TRUE) THEN
          INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
            (4, -1, 'Appender call: ' || COALESCE(CALL,'NULL'));
         END IF;
         PREPARE STMT FROM CALL;
         IF (CONT = TRUE) THEN
          EXECUTE STMT USING LOG_ID, LEV_ID, NEW_MESSAGE, CONFIGURATION;
         END IF;
        END DYNAMIC;
     END CASE;
    ELSE
       -- Internal logging.
     IF (INTERNAL = TRUE) THEN
      INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
        (4, -1, 'Non active logger' );
     END IF;
    END IF;
    FETCH REFERENCES INTO LOGGER_ID_FETCHED, CURRENT_APPENDER_NAME, APPENDER_ID,
      CONFIGURATION, PATTERN, LVL_REF, APPEND_NAME;
   END WHILE;
   CLOSE REFERENCES;
  ELSEIF (LOG_ID = -1) THEN
   -- When the logger id is -1, this is for internal logging.
   CALL LOG_TABLES(LOG_ID, LEV_ID, MESSAGE);
  END IF;
 END P_LOG @

-- MACROS

/**
 * Logs a message at debug (5) level. This method reduces the quantity of
 * internal calls by one.
 *
 * IN LOGGER_ID
 *   This is the associated logger of the provided message.
 * IN MESSAGE
 *   Message to log.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE DEBUG (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID DEFAULT 0,
  IN MESSAGE ANCHOR MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_DEBUG
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_DEBUG: BEGIN
  -- Handles the limit cascade call.
  DECLARE EXIT HANDLER FOR NESTED_LIMIT_ACHIEVED
   BEGIN
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES
    (2, 'LG001. Cascade call limit achieved, for DEBUG: ('
      || COALESCE(LOGGER_ID, -1) || ') ' || COALESCE(MESSAGE, 'null'));
    RESIGNAL SQLSTATE 'LG001'
      SET MESSAGE_TEXT = 'Cascade call limit achieved. Log message was written';
   END;

  CALL LOG (LOGGER_ID, 5, MESSAGE);
 END P_DEBUG @

/**
 * Logs a message at info (4) level. This method reduces the quantity of
 * internal calls by one.
 *
 * IN LOGGER_ID
 *   This is the associated logger of the provided message.
 * IN MESSAGE
 *   Message to log.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE INFO (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID DEFAULT 0,
  IN MESSAGE ANCHOR MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_INFO
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_INFO: BEGIN
  -- Handles the limit cascade call.
  DECLARE EXIT HANDLER FOR NESTED_LIMIT_ACHIEVED
   BEGIN
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES
    (2, 'LG001. Cascade call limit achieved, for INFO: ('
      || COALESCE(LOGGER_ID, -1) || ') ' || COALESCE(MESSAGE, 'null'));
    RESIGNAL SQLSTATE 'LG001'
      SET MESSAGE_TEXT = 'Cascade call limit achieved. Log message was written';
   END;

  CALL LOG (LOGGER_ID, 4, MESSAGE);
 END P_INFO @

/**
 * Logs a message at warn (3) level. This method reduces the quantity of
 * internal calls by one.
 *
 * IN LOGGER_ID
 *   This is the associated logger of the provided message.
 * IN MESSAGE
 *   Message to log.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE WARN (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID DEFAULT 0,
  IN MESSAGE ANCHOR MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_WARN
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_WARN: BEGIN
  -- Handles the limit cascade call.
  DECLARE EXIT HANDLER FOR NESTED_LIMIT_ACHIEVED
   BEGIN
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES
    (2, 'LG001. Cascade call limit achieved, for WARN: ('
      || COALESCE(LOGGER_ID, -1) || ') ' || COALESCE(MESSAGE, 'null'));
    RESIGNAL SQLSTATE 'LG001'
      SET MESSAGE_TEXT = 'Cascade call limit achieved. Log message was written';
   END;

  CALL LOG (LOGGER_ID, 3, MESSAGE);
 END P_WARN @

/**
 * Logs a message at error (2) level. This method reduces the quantity of
 * internal calls by one.
 *
 * IN LOGGER_ID
 *   This is the associated logger of the provided message.
 * IN MESSAGE
 *   Message to log.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE ERROR (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID DEFAULT 0,
  IN MESSAGE ANCHOR MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_ERROR
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_ERROR: BEGIN
  -- Handles the limit cascade call.
  DECLARE EXIT HANDLER FOR NESTED_LIMIT_ACHIEVED
   BEGIN
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES
    (2, 'LG001. Cascade call limit achieved, for ERROR: ('
      || COALESCE(LOGGER_ID, -1) || ') ' || COALESCE(MESSAGE, 'null'));
    RESIGNAL SQLSTATE 'LG001'
      SET MESSAGE_TEXT = 'Cascade call limit achieved. Log message was written';
   END;

  CALL LOG (LOGGER_ID, 2, MESSAGE);
 END P_ERROR @

/**
 * Logs a message at fatal (1) level. This method reduces the quantity of
 * internal calls by one.
 *
 * IN LOGGER_ID
 *   This is the associated logger of the provided message.
 * IN MESSAGE
 *   Message to log.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE FATAL (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID DEFAULT 0,
  IN MESSAGE ANCHOR MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_FATAL
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_FATAL: BEGIN
  -- Handles the limit cascade call.
  DECLARE EXIT HANDLER FOR NESTED_LIMIT_ACHIEVED
   BEGIN
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES
    (2, 'LG001. Cascade call limit achieved, for FATAL: ('
      || COALESCE(LOGGER_ID, -1) || ') ' || COALESCE(MESSAGE, 'null'));
    RESIGNAL SQLSTATE 'LG001'
      SET MESSAGE_TEXT = 'Cascade call limit achieved. Log message was written';
   END;

  CALL LOG (LOGGER_ID, 1, MESSAGE);
 END P_FATAL @

