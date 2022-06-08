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
 * Implementation of the included appenders. Here you can find how log4db2
 * interacts with different components to log messages.
 *
 * Version: 2012-10-15 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET PATH = SYSPROC, LOGGER_1RC, SYSIBMADM @

/**
 * Writes the given message in the log table. This is a pure SQL implementation,
 * without any external call. If there is not a partition to insert in the LOGS
 * table, it will add an extra partition.
 *
 * IN LOGGER_ID
 *   Identification of the associated logger.
 * IN LEVEL_ID
 *   Identification of the associates level.
 * IN MESSAGE
 *   Descriptive message to write in the log table.
 * TESTS
 *   TestsLogs: Validates that the messages are well written.
 */
ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG_TABLES (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_LOG_TABLES
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
 P_LOG_TABLES: BEGIN
  DECLARE NO_PARTITION CONDITION FOR SQLSTATE '22525';
  DECLARE PARTITION_EXIST CONDITION FOR SQLSTATE '56016';
  -- If the partition already exist, just continue.
  -- This could happen when parallel execution.
  DECLARE CONTINUE HANDLER FOR PARTITION_EXIST
   BEGIN
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
      (LEVEL_ID, LOGGER_ID, MESSAGE);
   END;
  DECLARE CONTINUE HANDLER FOR NO_PARTITION
   BEGIN
    DECLARE STMT VARCHAR(256);
    SET STMT = 'ALTER TABLE LOGS ADD PARTITION STARTING ''' || CURRENT DATE
      || ''' ENDING ''' || (CURRENT DATE + 1 DAY) || ''' EXCLUSIVE';
    CALL SYSIBMADM.DBMS_OUTPUT.PUT_LINE('No partition to insert logs. '
      || 'Execute:');
    CALL SYSIBMADM.DBMS_OUTPUT.PUT_LINE(STMT);
   END;

  INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
    (LEVEL_ID, LOGGER_ID, MESSAGE);
 END P_LOG_TABLES @

/**
 * Writes the given message in the log table. This is a pure SQL implementation,
 * without any external call. This procedure is exactly the same as LOG_TABLES,
 * the difference is that this is declared as Autonomous. If there is not a
 * partition to insert in the LOGS table, it will add an extra partition.
 *
 * IN LOGGER_ID
 *   Identification of the associated logger.
 * IN LEVEL_ID
 *   Identification of the associates level.
 * IN MESSAGE
 *   Descriptive message to write in the log table.
 * TESTS
 *   TestsLogs: Validates that the messages are well written.
 */
ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG_TABLES_AUTONOMOUS (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR MESSAGE
  )
  LANGUAGE SQL
  SPECIFIC P_LOG_TABLES_AUTONOMOUS
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  AUTONOMOUS -- Transaction independent.
  NO EXTERNAL ACTION
 P_LOG_TABLES_AUTONOMOUS: BEGIN
  DECLARE NO_PARTITION CONDITION FOR SQLSTATE '22525';
  DECLARE PARTITION_EXIST CONDITION FOR SQLSTATE '56016';
  -- If the partition already exist, just continue.
  -- This could happen when parallel execution.
  DECLARE CONTINUE HANDLER FOR PARTITION_EXIST
   BEGIN
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
      (LEVEL_ID, LOGGER_ID, MESSAGE);
   END;
  DECLARE CONTINUE HANDLER FOR NO_PARTITION
   BEGIN
    DECLARE STMT VARCHAR(256);
    SET STMT = 'ALTER TABLE LOGS ADD PARTITION STARTING ''' || CURRENT DATE
      || ''' ENDING ''' || (CURRENT DATE + 1 DAY) || ''' EXCLUSIVE';
    CALL SYSIBMADM.DBMS_OUTPUT.PUT_LINE('No partition to insert logs. '
      || 'Execute:');
    CALL SYSIBMADM.DBMS_OUTPUT.PUT_LINE(STMT);
   END;

  INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
    (LEVEL_ID, LOGGER_ID, MESSAGE);
 END P_LOG_TABLES_AUTONOMOUS @

/**
 * TODO Writes the provided message in the db2diag.log file (DIAGPATH) via
 * db2AdminMsgWrite. PUBLISH to ADD.
 *
 * IN LOGGER_ID
 *   Identification of the associated logger.
 * IN LEVEL_ID
 *   Identification of the associates level.
 * IN MESSAGE
 *   Descriptive message to write in the log table.
 * IN CONFIGURATION
 *   TODO Any particular configuration for the appender.
 */
ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG_DB2DIAG (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  ) @

/**
 * Handle for DB2Logger.
 */
ALTER MODULE LOGGER PUBLISH
  VARIABLE DB2LOGGER_HANDLER CHAR(160) FOR BIT DATA DEFAULT NULL @

/**
 * Writes the provided message in the DB2LOGGER. This is an external logging
 * facility implemented in C, and that has only two levels for loggers.
 *
 * For more information:
 * - http://www.ibm.com/developerworks/data/library/techarticle/dm-0601khatri/
 * - http://www.zinox.com/node/89
 *
 * IN LOGGER_ID
 *   Identification of the associated logger.
 * IN LEVEL_ID
 *   Identification of the associates level.
 * IN MESSAGE
 *   Descriptive message to write in the log table.
 * IN CONFIGURATION
 *   Any particular configuration for the appender. Not used for the moment.
 */
ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG_DB2LOGGER (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  )
  LANGUAGE SQL
  SPECIFIC P_LOG_DB2LOGGER
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
 P_LOG_DB2LOGGER: BEGIN
  DECLARE STMT STATEMENT;

  IF (LEVEL_ID <= DEFAULT_LEVEL) THEN
   PREPARE STMT FROM 'CALL DB2.LOGINFO(?, ?)';
  ELSE
   PREPARE STMT FROM 'CALL DB2.LOGGER(?, ?)';
  END IF;
  EXECUTE STMT USING DB2LOGGER_HANDLER, MESSAGE;
 END P_LOG_DB2LOGGER  @

/**
 * TODO Writes the provided message in the Java configured tool. This
 * logger could use log4j or slf4j/logback as back-end, it depends on the Java
 * implementation. PUBLISH to ADD.
 *
 * IN LOGGER_ID
 *   Identification of the associated logger.
 * IN LEVEL_ID
 *   Identification of the associates level.
 * IN MESSAGE
 *   Descriptive message to write in the log table.
 * IN CONFIGURATION
 *   TODO Any particular configuration for the appender.
 */
ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG_JAVA (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  ) 
  SPECIFIC P_LOG_JAVA @

/**
 * Drops the messages.
 *
 * IN LOGGER_ID
 *   Identification of the associated logger.
 * IN LEVEL_ID
 *   Identification of the associates level.
 * IN MESSAGE
 *   Descriptive message to write in the log table.
 * IN CONFIGURATION
 *   Any particular configuration for the appender.
 */
ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG_NULL (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  )
  LANGUAGE SQL
  SPECIFIC P_LOG_NULL
  DYNAMIC RESULT SETS 0
  DETERMINISTIC
  NO EXTERNAL ACTION
 P_LOG_NULL: BEGIN
 END P_LOG_NULL @

