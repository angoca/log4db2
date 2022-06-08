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
 * Tests the layout of the conf_appenders table.
 *
 * Version: 2022-06-07 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOG4DB2_LAYOUT @

BEGIN
 DECLARE STATEMENT VARCHAR(128);
 DECLARE CONTINUE HANDLER FOR SQLSTATE '42710' BEGIN END;
 SET STATEMENT = 'CREATE SCHEMA LOG4DB2_LAYOUT';
 EXECUTE IMMEDIATE STATEMENT;
END @

-- Test fixtures
CREATE OR REPLACE PROCEDURE ONE_TIME_SETUP()
 BEGIN
  CALL LOGGER.DEACTIVATE_CACHE();
  CALL DB2UNIT.SET_AUTONOMOUS(FALSE);
 END @

CREATE OR REPLACE PROCEDURE SETUP()
 BEGIN
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
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
    VALUES ('Tables', 1, NULL, '[%p] %c -%T%m');
 END @

CREATE OR REPLACE PROCEDURE ONE_TIME_TEAR_DOWN()
 BEGIN
  CALL LOGGER_1RC.LOGADMIN.RESET_TABLES();
 END @

-- Tests

-- Test01: Check the id.
CREATE OR REPLACE PROCEDURE TEST_01()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test1';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET APPENDER_NAME='Test1';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%I');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, 'Message test');
  SET EXPECTED_MSG=SYSPROC.MON_GET_APPLICATION_ID();
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test01: Check the id', EXPECTED_MSG,
    ACTUAL_MSG);
 END @

-- Test02: Check the application name.
CREATE OR REPLACE PROCEDURE TEST_02()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test2';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET APPENDER_NAME='Test2';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%N');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, 'Message test');
  SELECT APPLICATION_NAME INTO EXPECTED_MSG
    FROM TABLE(SYSPROC.MON_GET_CONNECTION(SYSPROC.MON_GET_APPLICATION_HANDLE(),
    -1));
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test02: Check the application name',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test03: Check the handle.
CREATE OR REPLACE PROCEDURE TEST_03()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test3';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET APPENDER_NAME='Test3';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%H');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, 'Message test');
  SET EXPECTED_MSG=SYSPROC.MON_GET_APPLICATION_HANDLE();
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test03: Check the handle', EXPECTED_MSG,
    ACTUAL_MSG);
 END @

-- Test04: Check the current user.
CREATE OR REPLACE PROCEDURE TEST_04()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test4';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET APPENDER_NAME='Test4';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%S');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, 'Message test');
  SET EXPECTED_MSG=TRIM(SESSION_USER);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test04: Check the current user',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test05: Check the client.
CREATE OR REPLACE PROCEDURE TEST_05()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test5';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET APPENDER_NAME='Test5';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%C');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, 'Message test');
  SET EXPECTED_MSG=CLIENT WRKSTNNAME;
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test05: Check the client',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test06: Check the message.
CREATE OR REPLACE PROCEDURE TEST_06()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test6';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET APPENDER_NAME='Test6';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%m');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  SET EXPECTED_MSG='No message';
  CALL LOGGER.DEBUG(LOGGER_ID, EXPECTED_MSG);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test06: Check the message',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test07: Check the message null.
CREATE OR REPLACE PROCEDURE TEST_07()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test7';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET APPENDER_NAME='Test7';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%m');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, NULL);
  SET EXPECTED_MSG='No message';
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test07: Check the message null',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test08: Check the logger - ROOT.
CREATE OR REPLACE PROCEDURE TEST_08()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET APPENDER_NAME='Test8';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%c');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, APPENDER_ID);
  CALL LOGGER.DEBUG(0, 'Message test');
  SET EXPECTED_MSG='ROOT';
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test08: Check the logger - ROOT',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test09: Check the logger - A.
CREATE OR REPLACE PROCEDURE TEST_09()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test9';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET APPENDER_NAME='Test9';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%c');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, 'Message test');
  SET EXPECTED_MSG=LOGGER_NAME;
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
     FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test09: Check the logger - A',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test10: Check the logger - A.B.
CREATE OR REPLACE PROCEDURE TEST_10()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE PARENT_LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test10';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, PARENT_LOGGER_ID);
  SET LOGGER_NAME = 'Test10.B';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = 5
    WHERE LOGGER_ID = LOGGER_ID;
  SET APPENDER_NAME='Test10';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%c');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, 'Message test');
  SET EXPECTED_MSG='Test10.B';
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test10: Check the logger - A.B',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test11: Check the logger - A.B.C.
CREATE OR REPLACE PROCEDURE TEST_11()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE PARENT_LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test11';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, PARENT_LOGGER_ID);
  SET LOGGER_NAME = 'Test11.B';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET PARENT_LOGGER_ID=LOGGER_ID;
  SET LOGGER_NAME = 'Test11.B.C';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET APPENDER_NAME='Test11';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%c');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, 'Message test');
  SET EXPECTED_MSG=LOGGER_NAME;
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test11: Check the logger - A.B.C',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test12: Check the level.
CREATE OR REPLACE PROCEDURE TEST_12()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE LVL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test12';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET LVL_ID=5;
  SET APPENDER_NAME='Test12';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%p');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.LOG(LOGGER_ID, LVL_ID, 'Message test');
  SELECT UCASE(L.NAME) INTO EXPECTED_MSG
    FROM LOGDATA.LEVELS L
    WHERE L.LEVEL_ID = LVL_ID
    WITH UR;
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test12: Check the level',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test13: Check the nesting level.
CREATE OR REPLACE PROCEDURE TEST_13()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE LVL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE AUTONOMOUS BOOLEAN;

  SET LOGGER_NAME = 'Test13';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET LVL_ID=5;
  SET APPENDER_NAME='Test13';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%L');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.LOG(LOGGER_ID, LVL_ID, 'Message test');
  SET AUTONOMOUS = DB2UNIT.GET_AUTONOMOUS();
  IF (AUTONOMOUS = TRUE) THEN
   SET EXPECTED_MSG = '4';
  ELSE
   SET EXPECTED_MSG = '7';
  END IF;
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test13: Check the nesting level',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test14: Check the pattern layout static.
CREATE OR REPLACE PROCEDURE TEST_14()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test14';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET APPENDER_NAME='Test14';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, 'static layout');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, NULL);
  SET EXPECTED_MSG='static layout';
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test14: Check the pattern layout static',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test15: Check the pattern layout empty.
CREATE OR REPLACE PROCEDURE TEST_15()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test15';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET APPENDER_NAME='Test15';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, NULL);
  SET EXPECTED_MSG='';
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test15: Check the pattern layout empty',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test16: Check the pattern layout %a.
CREATE OR REPLACE PROCEDURE TEST_16()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test16';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET APPENDER_NAME='Test16';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%a');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, NULL);
  SET EXPECTED_MSG='%a';
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test16: Check the pattern layout %a',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test17: Check the pattern layout with reserved words.
CREATE OR REPLACE PROCEDURE TEST_17()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET LOGGER_NAME = 'Test17';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET APPENDER_NAME='Test17';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%m');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.DEBUG(LOGGER_ID, '%c %m %p %C %H %I %L %N %S');
  SET EXPECTED_MSG='%c %m %p %C %H %I %L %N %S';
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test17: Check the pattern layout reserved '
    || 'words', EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test18: Check the tabulation.
CREATE OR REPLACE PROCEDURE TEST_18()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE LVL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID;
  DECLARE APPENDER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE AUTONOMOUS BOOLEAN;

  SET LOGGER_NAME = 'Test18';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
  SET LVL_ID=5;
  SET APPENDER_NAME='Test18';
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
    VALUES (APPENDER_NAME, 1, NULL, '%T-');
  SELECT MAX(REF_ID) INTO APPENDER_ID
    FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (LOGGER_ID, APPENDER_ID);
  CALL LOGGER.LOG(LOGGER_ID, LVL_ID, 'Message test');
  SET AUTONOMOUS = DB2UNIT.GET_AUTONOMOUS();
  IF (AUTONOMOUS = TRUE) THEN
   SET EXPECTED_MSG = '    -';
  ELSE
   SET EXPECTED_MSG = '       -';
  END IF;
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ)
      FROM LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test18: Check the tabulation',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Register the suite.
CALL DB2UNIT.REGISTER_SUITE(CURRENT SCHEMA) @

