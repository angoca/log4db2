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

/**
 * Tests for the dynamic appenders.
 *
 * Version: 2014-04-21 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOGGER_1RC @

BEGIN
 DECLARE STATEMENT VARCHAR(128);
 DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
 SET STATEMENT = 'ALTER MODULE LOGGER DROP SPECIFIC PROCEDURE P_TEST_LOG_RESIGNAL';
 EXECUTE IMMEDIATE STATEMENT;
 SET STATEMENT = 'ALTER MODULE LOGGER DROP SPECIFIC PROCEDURE P_TEST_LOG_SIGNAL';
 EXECUTE IMMEDIATE STATEMENT;
 SET STATEMENT = 'ALTER MODULE LOGGER DROP SPECIFIC PROCEDURE P_TEST_LOG_SIMILAR';
 EXECUTE IMMEDIATE STATEMENT;
 SET STATEMENT = 'ALTER MODULE LOGGER DROP SPECIFIC PROCEDURE P_TEST_LOG_TABLES_LONG';
 EXECUTE IMMEDIATE STATEMENT;
 SET STATEMENT = 'ALTER MODULE LOGGER DROP SPECIFIC PROCEDURE P_TEST_LOG_PUBLISHED';
 EXECUTE IMMEDIATE STATEMENT;
END @

ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG_PUBLISHED (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGGER.MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  ) SPECIFIC P_TEST_LOG_PUBLISHED@

ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG_TABLES (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGGER.MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  )
  SPECIFIC P_TEST_LOG_TABLES_LONG
 BEGIN
  CALL LOG_TABLES(LOGGER_ID, LEVEL_ID, MESSAGE);
 END @

ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG_SIMILIAR (
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION,
  IN MESSAGE ANCHOR LOGGER.MESSAGE,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  )
  SPECIFIC P_TEST_LOG_SIMILAR
 BEGIN
 END @

ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG_SIGNAL (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGGER.MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  )
  SPECIFIC P_TEST_LOG_SIGNAL
 BEGIN
  SIGNAL SQLSTATE VALUE 'TEST1'
    SET MESSAGE_TEXT = 'Error from LOG_SIGNAL';
 END @

ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG_RESIGNAL (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGGER.MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  )
  SPECIFIC P_TEST_LOG_RESIGNAL
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'TES2A'
    RESIGNAL SQLSTATE 'TES2B'
    SET MESSAGE_TEXT = 'Resignal message';
   SIGNAL SQLSTATE VALUE 'TES2A'
     SET MESSAGE_TEXT = 'Error from LOG_RESIGNAL';
  END @

SET PATH = LOG4DB2_DYNAMIC_APPENDERS, LOGGER_1RC @

BEGIN
 DECLARE STATEMENT VARCHAR(128);
 DECLARE CONTINUE HANDLER FOR SQLSTATE '42710' BEGIN END;
 SET STATEMENT = 'CREATE SCHEMA LOG4DB2_DYNAMIC_APPENDERS';
 EXECUTE IMMEDIATE STATEMENT;
END @

SET CURRENT SCHEMA LOG4DB2_DYNAMIC_APPENDERS @

-- Test fixtures
CREATE OR REPLACE PROCEDURE ONE_TIME_SETUP()
 BEGIN
  DELETE FROM LOGDATA.REFERENCES;
  DELETE FROM LOGDATA.CONF_APPENDERS;
  DELETE FROM LOGDATA.APPENDERS;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME)
    VALUES (0, 'Null'),
           (1, 'Tables');
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = 'false'
    WHERE KEY = 'logInternals';
  CALL LOGGER.REFRESH_CACHE();
 END @

CREATE OR REPLACE PROCEDURE SETUP()
 BEGIN
  DELETE FROM LOGDATA.CONF_APPENDERS;
  DELETE FROM LOGDATA.APPENDERS
    WHERE APPENDER_ID >= 2;
 END @

CREATE OR REPLACE PROCEDURE TEAR_DOWN()
 BEGIN
  DELETE FROM LOGDATA.LOGS;
 END @

CREATE OR REPLACE PROCEDURE ONE_TIME_TEAR_DOWN()
 BEGIN
  CALL LOGGER_1RC.LOGADMIN.RESET_TABLES();
 END @

-- Tests

-- Test01: Inserts in table using dynamic appender.
CREATE OR REPLACE PROCEDURE TEST_01()
 BEGIN
  DECLARE EXPECTED_QTY SMALLINT;
  DECLARE ACTUAL_QTY SMALLINT;

  SET EXPECTED_QTY = 1;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (2, 'TABLES');
  INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN,
    LEVEL_ID) VALUES (1, 'test1', 2, '%m', null);
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, 1);
  CALL LOGGER.FATAL(0, 'Message test 1.');
  SELECT COUNT(1) INTO ACTUAL_QTY
    FROM LOGS
    WHERE MESSAGE LIKE '%Message test 1.%';

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test01: Inserts in table using dynamic '
    || 'appender', EXPECTED_QTY, ACTUAL_QTY);
 END @

-- Test02: Inserts in table using dynamic and built-in appender.
CREATE OR REPLACE PROCEDURE TEST_02()
 BEGIN
  DECLARE EXPECTED_QTY SMALLINT;
  DECLARE ACTUAL_QTY SMALLINT;

  SET EXPECTED_QTY = 2;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (2, 'TABLES');
  INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN,
    LEVEL_ID) VALUES (1, 'test2A', 1, '%m', null);
  INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN,
    LEVEL_ID) VALUES (2, 'test2B', 2, '%m', null);
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, 1);
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, 2);
  CALL LOGGER.FATAL(0, 'Message test 2.');
  SELECT COUNT(1) INTO ACTUAL_QTY
    FROM LOGS
    WHERE MESSAGE LIKE '%Message test 2.%';

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test02: Inserts in table using dynamic and '
    || 'built-in appender', EXPECTED_QTY, ACTUAL_QTY);
 END @

-- Test03: Inserts in table using built-in appender.
CREATE OR REPLACE PROCEDURE TEST_03()
 BEGIN
  DECLARE EXPECTED_QTY SMALLINT;
  DECLARE ACTUAL_QTY SMALLINT;

  SET EXPECTED_QTY = 1;
  INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN,
    LEVEL_ID) VALUES (1, 'test3', 1, '%m', null);
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, 1);
  CALL LOGGER.FATAL(0, 'Message test 3.');
  SELECT COUNT(1) INTO ACTUAL_QTY
    FROM LOGS
    WHERE MESSAGE LIKE '%Message test 3.%';

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test03: Inserts in table using built-in '
    || 'appender', EXPECTED_QTY, ACTUAL_QTY);
 END @

-- Test04: Tries to use an inexistant appender.
CREATE OR REPLACE PROCEDURE TEST_04()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE MESSAGE ANCHOR LOGDATA.LOGS.MESSAGE;

  SET MESSAGE = 'Message test 4.';
  SET EXPECTED_MSG = 'Non-existent appender: test4=[FATAL] ' || MESSAGE;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (4, 'INEXISTANT');
  INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN,
    LEVEL_ID) VALUES (1, 'test4', 4, '[%p] %m', null);
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, 1);
  CALL LOGGER.FATAL(0, MESSAGE);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test04: Tries to use an inexistant '
    || 'appender', EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test05: Tries to use a published appender.
CREATE OR REPLACE PROCEDURE TEST_05()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE MESSAGE ANCHOR LOGDATA.LOGS.MESSAGE;

  SET MESSAGE = 'Message test 5.';
  SET EXPECTED_MSG = 'Appender not available: test5=[FATAL] ' || MESSAGE;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (5, 'PUBLISHED');
  INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN,
    LEVEL_ID) VALUES (1, 'test5', 5, '[%p] %m', null);
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, 1);
  CALL LOGGER.FATAL(0, MESSAGE);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test05: Tries to use a published appender',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test06: Tries to use a similar appender.
CREATE OR REPLACE PROCEDURE TEST_06()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE MESSAGE ANCHOR LOGDATA.LOGS.MESSAGE;

  SET MESSAGE = 'Message test 6.';
  SET EXPECTED_MSG = 'Non-existent appender: test6=[FATAL] ' || MESSAGE;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (6, 'SIMILAR');
  INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN,
    LEVEL_ID) VALUES (1, 'test6', 6, '[%p] %m', null);
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, 1);
  CALL LOGGER.FATAL(0, MESSAGE);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test06: Tries to use a similar appender',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test07: Tries to use an appender with signal.
CREATE OR REPLACE PROCEDURE TEST_07()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE MESSAGE ANCHOR LOGDATA.LOGS.MESSAGE;

  SET MESSAGE = 'Message test 7.';
  SET EXPECTED_MSG = 'Appender test7:-Exception SQLCode -438-SQLState TEST1='
    || MESSAGE;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (7, 'SIGNAL');
  INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN,
    LEVEL_ID) VALUES (1, 'test7', 7, '%m', null);
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, 1);
  CALL LOGGER.FATAL(0, MESSAGE);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test07: Tries to use an appender with '
    || 'signal', EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test08: Tries to use an appender with resignal.
CREATE OR REPLACE PROCEDURE TEST_08()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE MESSAGE ANCHOR LOGDATA.LOGS.MESSAGE;

  SET MESSAGE = 'Message test 8.';
  SET EXPECTED_MSG = 'Appender test8:-Exception SQLCode -438-SQLState TES2B='
    || MESSAGE;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (8, 'RESIGNAL');
  INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN,
    LEVEL_ID) VALUES (1, 'test8', 8, '[%p] %m', null);
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, 1);
  CALL LOGGER.FATAL(0, MESSAGE);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test08: Tries to use an appender with '
    || 'resignal', EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test09: Inserts in table using dynamic appender with pattern.
CREATE OR REPLACE PROCEDURE TEST_09()
 BEGIN
  DECLARE EXPECTED_QTY SMALLINT;
  DECLARE ACTUAL_QTY SMALLINT;
  DECLARE MESSAGE ANCHOR LOGDATA.LOGS.MESSAGE;

  SET MESSAGE = 'Message test 9.';
  SET EXPECTED_QTY = 1;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (2, 'TABLES');
  INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN,
    LEVEL_ID) VALUES (1, 'test1', 2, '[%p] %m', null);
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, 1);
  CALL LOGGER.FATAL(0, 'Message test 1.');
  SELECT COUNT(1) INTO ACTUAL_QTY
    FROM LOGS
    WHERE MESSAGE LIKE '%Message test 1.%';

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test09: Inserts in table using dynamic '
    || 'appender with pattern', EXPECTED_QTY, ACTUAL_QTY);
 END @

-- Register the suite.
CALL DB2UNIT.REGISTER_SUITE(CURRENT SCHEMA) @

