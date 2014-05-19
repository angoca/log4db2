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
 * Tests the log procedure.
 *
 * Version: 2014-04-21 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOG4DB2_LOGS @

CREATE SCHEMA LOG4DB2_LOGS @

-- Test fixtures
CREATE OR REPLACE PROCEDURE ONE_TIME_SETUP()
 BEGIN
  DELETE FROM LOGDATA.REFERENCES;
  DELETE FROM LOGDATA.CONF_APPENDERS;
  CALL LOGGER.REFRESH_CACHE();
 END @

CREATE OR REPLACE PROCEDURE SETUP()
 BEGIN
  DELETE FROM LOGDATA.REFERENCES;
  DELETE FROM LOGDATA.CONF_APPENDERS;
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES ('Tables', 1, NULL, '[%p] %c - %m');
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS));
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = 5
    WHERE LOGGER_ID = 0;
 END @

CREATE OR REPLACE PROCEDURE TEAR_DOWN()
 BEGIN
  DELETE FROM LOGDATA.REFERENCES;
  DELETE FROM LOGDATA.CONF_APPENDERS;
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES ('Tables', 1, NULL, '[%p] %c - %m');
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS));
  DELETE FROM LOGDATA.LOGS;
 END @

CREATE OR REPLACE PROCEDURE ONE_TIME_TEAR_DOWN()
 BEGIN
  -- Emtpy
 END @

-- Test01: Check message limit.
CREATE OR REPLACE PROCEDURE TEST_01()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;

  CALL LOGGER.GET_LOGGER('Test01', LOGGER_ID);
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES ('Test01', 1, NULL, '%m');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, '1234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012');
  SET EXPECTED_MSG='12345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '123456789012345678901234567890123456789012';
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
    FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test01: Check message limit', EXPECTED_MSG,
    ACTUAL_MSG);
 END @

-- Test02: Check message limit under.
CREATE OR REPLACE PROCEDURE TEST_02()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;

  CALL LOGGER.GET_LOGGER('Test02', LOGGER_ID);
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES ('Test02', 1, NULL, '%m%m%m%m%m%m%m%m%m%m%m%m%m%m%m%m');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, '123456789012345678901234567890');
  SET EXPECTED_MSG='12345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890';
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test02: Check message limit under',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test03: Check message limit equal.
CREATE OR REPLACE PROCEDURE TEST_03()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;

  CALL LOGGER.GET_LOGGER('Test03', LOGGER_ID);
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES ('Test04', 1, NULL, '%m%m%m%m%m%m%m%m%m%m%m%m%m%m%m%m%m12');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, '123456789012345678901234567890');
  SET EXPECTED_MSG='12345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '123456789012345678901234567890123456789012';
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
    FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test03: Check message limit equal',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test04: Check message limit one more.
CREATE OR REPLACE PROCEDURE TEST_04()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;

  CALL LOGGER.GET_LOGGER('Test04', LOGGER_ID);
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES ('Test04', 1, NULL, '%m%m%m%m%m%m%m%m%m%m%m%m%m%m%m%m%m123');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, '123456789012345678901234567890');
  SET EXPECTED_MSG='12345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '123456789012345678901234567890123456789012';
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test04: Check message limit one more',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test05: Check message limit more.
CREATE OR REPLACE PROCEDURE TEST_05()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;

  CALL LOGGER.GET_LOGGER('Test05', LOGGER_ID);
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES ('Test05', 1, NULL, '%m%m%m%m%m%m%m%m%m%m%m%m%m%m%m%m%m%m');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, '123456789012345678901234567890');
  SET EXPECTED_MSG='12345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '1234567890123456789012345678901234567890123456789012345678901234567890'
    || '123456789012345678901234567890123456789012';
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test05: Check message limit more',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test06: Check null logger_id.
CREATE OR REPLACE PROCEDURE TEST_06()
 BEGIN
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;

  SET LOGGER_ID = NULL;
  CALL LOGGER.LOG(LOGGER_ID, 5, 'Test6');
 END @

-- Test07: Check just message.
CREATE OR REPLACE PROCEDURE TEST_07()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_MSG='[WARN ] ROOT - Test07';
  CALL LOGGER.LOG(MESSAGE => 'Test07');
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test07: Check just message',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test08: Check message and logger.
CREATE OR REPLACE PROCEDURE TEST_08()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;

  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = 0
    WHERE LOGGER_ID = 0;
  CALL LOGGER.GET_LOGGER('Test08', LOGGER_ID);
  SET EXPECTED_MSG='[WARN ] Test08 - Message';
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = 5
    WHERE LOGGER_ID = LOGGER_ID;
  CALL LOGGER.LOG(LOGGER_ID, MESSAGE => 'Message');
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test08: Check message and logger',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test09: Check message and logger with param name.
CREATE OR REPLACE PROCEDURE TEST_09()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;

  CALL LOGGER.GET_LOGGER('Test09', LOGGER_ID);
  SET EXPECTED_MSG='[WARN ] Test09 - Message';
  CALL LOGGER.LOG(MESSAGE => 'Message', LOG_ID => LOGGER_ID);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test09: Check message and logger with '
    || 'param name', EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test10: Check message and level with param name.
CREATE OR REPLACE PROCEDURE TEST_10()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_MSG='[ERROR] ROOT - Message';
  CALL LOGGER.LOG( MESSAGE => 'Message', LEV_ID => 2);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test10: Check message and level with '
    || 'param name', EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test11: Check message, level and logger with param name.
CREATE OR REPLACE PROCEDURE TEST_11()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;

  CALL LOGGER.GET_LOGGER('Test11', LOGGER_ID);
  SET EXPECTED_MSG='[DEBUG] Test11 - Message';
  CALL LOGGER.LOG(MESSAGE => 'Message', LEV_ID => 5, LOG_ID => LOGGER_ID);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test11: Check message, level and logger '
    || 'with param name', EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test12: Check all null.
CREATE OR REPLACE PROCEDURE TEST_12()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_MSG='[WARN ] ROOT - No message';
  CALL LOGGER.LOG(NULL, NULL, NULL);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test12: Check all null', EXPECTED_MSG,
    ACTUAL_MSG);
 END @

-- Test13: Check log_id null.
CREATE OR REPLACE PROCEDURE TEST_13()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_MSG='[ERROR] ROOT - Message';
  CALL LOGGER.LOG(NULL, 2, 'Message');
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test13: Check log_id null', EXPECTED_MSG,
    ACTUAL_MSG);
 END @

-- Test14: Check lev_id null.
CREATE OR REPLACE PROCEDURE TEST_14()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_MSG='[WARN ] ROOT - Message';
  CALL LOGGER.LOG(0, NULL, 'Message');
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test14: Check lev_id null', EXPECTED_MSG,
    ACTUAL_MSG);
 END @

-- Test15: Check non existent log_id.
CREATE OR REPLACE PROCEDURE TEST_15()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_MSG='[ERROR] Unknown - Message';
  CALL LOGGER.LOG(32767, 2, 'Message');
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test15: Check non existent log_id',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test16: Check negative log_id.
CREATE OR REPLACE PROCEDURE TEST_16()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_MSG='[DEBUG] ROOT - Message';
  CALL LOGGER.LOG(-2, 5, 'Message');
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test16: Check negative log_id',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test17: Check inexistant lev_id.
CREATE OR REPLACE PROCEDURE TEST_17()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_MSG='[WARN ] ROOT - Message';
  CALL LOGGER.LOG(0, 32767, 'Message');
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test17: Check inexistant lev_id',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test18: Check negative lev_id.
CREATE OR REPLACE PROCEDURE TEST_18()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_MSG='[WARN ] ROOT - Message';
  CALL LOGGER.LOG(0, -1, 'Message');
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test18: Check negative lev_id',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test19: Check 0 lev_id.
CREATE OR REPLACE PROCEDURE TEST_19()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_MSG='Check19';
  INSERT INTO LOGS (MESSAGE) VALUES (EXPECTED_MSG);
  CALL LOGGER.LOG(0, 0, 'Message');
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test19: Check 0 lev_id',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test20: Check both null.
CREATE OR REPLACE PROCEDURE TEST_20()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_MSG='[WARN ] ROOT - Message';
  CALL LOGGER.LOG(NULL, NULL, 'Message');
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test20: Check both null',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test21: Check both null inexistant.
CREATE OR REPLACE PROCEDURE TEST_21()
 BEGIN
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_MSG='[WARN ] Unknown - Message';
  CALL LOGGER.LOG(32767, 32767, 'Message');
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE = (SELECT MAX(DATE)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test21: Check both null inexistant',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

