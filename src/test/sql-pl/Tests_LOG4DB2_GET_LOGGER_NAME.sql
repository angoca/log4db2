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
 * Tests for the GetLoggerName function.
 *
 * Version: 2022-06-07 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOG4DB2_GET_LOGGER_NAME @

BEGIN
 DECLARE STATEMENT VARCHAR(128);
 DECLARE CONTINUE HANDLER FOR SQLSTATE '42710' BEGIN END;
 SET STATEMENT = 'CREATE SCHEMA LOG4DB2_GET_LOGGER_NAME';
 EXECUTE IMMEDIATE STATEMENT;
END @

-- Test fixtures
CREATE OR REPLACE PROCEDURE ONE_TIME_SETUP()
 BEGIN
  CALL DB2UNIT.SET_AUTONOMOUS(FALSE);
  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID <> 0;
  CALL LOGGER.DEACTIVATE_CACHE();
 END @

CREATE OR REPLACE PROCEDURE SETUP()
 BEGIN
  -- Empty
 END @

CREATE OR REPLACE PROCEDURE TEAR_DOWN()
 BEGIN
  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID <> 0;
  DELETE FROM LOGDATA.LOGS;
 END @

CREATE OR REPLACE PROCEDURE ONE_TIME_TEAR_DOWN()
 BEGIN
  CALL LOGGER_1.LOGADMIN.RESET_TABLES();
 END @

-- Tests

-- Test01: Test ID null.
CREATE OR REPLACE PROCEDURE TEST_01()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE ACTUAL_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;

  SET ID = NULL;
  SET EXPECTED_RET = '-internal-';
  SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test01: Test ID null',
    EXPECTED_RET, ACTUAL_RET);
 END @

-- Test02: Test ID -1.
CREATE OR REPLACE PROCEDURE TEST_02()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE ACTUAL_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;

  SET ID = -1;
  SET EXPECTED_RET = '-internal-';
  SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test02: Test ID -1',
    EXPECTED_RET, ACTUAL_RET);
 END @

-- Test03: Test ID -2.
CREATE OR REPLACE PROCEDURE TEST_03()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE ACTUAL_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;

  SET ID = -2;
  SET EXPECTED_RET = '-INVALID-';
  SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test03: Test ID -2',
    EXPECTED_RET, ACTUAL_RET);
 END @

-- Test04: Test ID negative.
CREATE OR REPLACE PROCEDURE TEST_04()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE ACTUAL_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;

  SET ID = -32765;
  SET EXPECTED_RET = '-INVALID-';
  SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test04: Test ID negative',
    EXPECTED_RET, ACTUAL_RET);
 END @

-- Test05: Test ID 0.
CREATE OR REPLACE PROCEDURE TEST_05()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE ACTUAL_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;

  SET ID = 0;
  SET EXPECTED_RET = 'ROOT';
  SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test05: Test ID 0',
    EXPECTED_RET, ACTUAL_RET);
 END @

-- Test06: Test ID inexistant.
CREATE OR REPLACE PROCEDURE TEST_06()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE ACTUAL_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;

  SET ID = 32765;
  SET EXPECTED_RET = 'Unknown';
  SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test06: Test ID inexistant',
    EXPECTED_RET, ACTUAL_RET);
 END @

-- Test07: Test one level.
CREATE OR REPLACE PROCEDURE TEST_07()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE ACTUAL_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;

  SET EXPECTED_RET = 'logger1';
  CALL LOGGER.GET_LOGGER(EXPECTED_RET, ID);
  SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test07: Test one level',
    EXPECTED_RET, ACTUAL_RET);
 END @

-- Test08: Test two levels.
CREATE OR REPLACE PROCEDURE TEST_08()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE ACTUAL_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;

  SET EXPECTED_RET = 'logger1.logger2';
  CALL LOGGER.GET_LOGGER(EXPECTED_RET, ID);
  SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test08: Test two levels',
    EXPECTED_RET, ACTUAL_RET);
 END @

-- Test09: Test three levels.
CREATE OR REPLACE PROCEDURE TEST_09()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE ACTUAL_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;

  SET EXPECTED_RET = 'logger1.logger2.logger3';
  CALL LOGGER.GET_LOGGER(EXPECTED_RET, ID);
  SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test09: Test three levels',
    EXPECTED_RET, ACTUAL_RET);
 END @

-- Test10: Test 30 levels.
-- This is the level established to make all functions work. However,
-- GET_LOGGER procedure could accept until 60 levels.
CREATE OR REPLACE PROCEDURE TEST_10()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE ACTUAL_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;

  SET EXPECTED_RET = '1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8'
    || '.9.0';
  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID <> 0;
  CALL LOGGER.DEACTIVATE_CACHE();
  CALL LOGGER.GET_LOGGER(EXPECTED_RET, ID);
  SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test10: Test 30 levels',
    EXPECTED_RET, ACTUAL_RET);
 END @

-- Test11: Test 31 levels.
CREATE OR REPLACE PROCEDURE TEST_11()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE EXPECTED_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE ACTUAL_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_ID = 0;
  SET LOGGER_NAME = '1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8'
    || '.9.0.1';
  SET EXPECTED_MSG = 'LG001. Cascade call limit achieved, for GET_LOGGER: '
    || LOGGER_NAME;
  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID <> 0;
  CALL LOGGER.DEACTIVATE_CACHE();
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, ACTUAL_ID);
SELECT MESSAGE INTO ACTUAL_MSG
  FROM LOGS
  WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test11: Test 31 levels',
    EXPECTED_ID, ACTUAL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test11: Test 31 levels',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test12: Test 60 levels.
CREATE OR REPLACE PROCEDURE TEST_12()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE EXPECTED_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE ACTUAL_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_ID = 0;
  SET LOGGER_NAME = '1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8'
    || '.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0';
  SET EXPECTED_MSG = 'LG001. Cascade call limit achieved, for GET_LOGGER: '
    || LOGGER_NAME;
  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID <> 0;
  CALL LOGGER.DEACTIVATE_CACHE();
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, ACTUAL_ID);
  SELECT MESSAGE INTO ACTUAL_MSG
    FROM LOGS
    WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test12: Test 60 levels',
    EXPECTED_ID, ACTUAL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test12: Test 60 levels',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Test13: Test 61 levels.
-- This is the maximum possible for GET_LOGGERS, however, for other functions
-- this level is too much (triggers).
CREATE OR REPLACE PROCEDURE TEST_13()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE EXPECTED_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE ACTUAL_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

  SET EXPECTED_ID = 0;
  SET LOGGER_NAME = '1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8'
    || '.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1';
  SET EXPECTED_MSG = 'LG001. Cascade call limit achieved, for GET_LOGGER: '
    || LOGGER_NAME;
  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID <> 0;
  CALL LOGGER.DEACTIVATE_CACHE();
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, ACTUAL_ID);
SELECT MESSAGE INTO ACTUAL_MSG
  FROM LOGS
  WHERE DATE_UNIQ = (SELECT MAX(DATE_UNIQ) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test13: Test 61 levels',
    EXPECTED_ID, ACTUAL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test13: Test 61 levels',
    EXPECTED_MSG, ACTUAL_MSG);
 END @

-- Register the suite.
CALL DB2UNIT.REGISTER_SUITE(CURRENT SCHEMA) @

