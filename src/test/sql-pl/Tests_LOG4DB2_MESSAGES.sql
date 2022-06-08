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
 * Tests for generated messages.
 *
 * Version: 2022-06-07 v1
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOG4DB2_MESSAGES @

SET PATH = "SYSIBM", "SYSFUN", "SYSPROC", "SYSIBMADM", LOG4DB2_MESSAGES @

BEGIN
 DECLARE STATEMENT VARCHAR(128);
 DECLARE CONTINUE HANDLER FOR SQLSTATE '42710' BEGIN END;
 SET STATEMENT = 'CREATE SCHEMA LOG4DB2_MESSAGES';
 EXECUTE IMMEDIATE STATEMENT;
END @

-- Install

CREATE OR REPLACE PROCEDURE CASCADE (
  IN VAL INTEGER
  )
 SPECIFIC MESSAGE_CASCADE
 BEGIN
  DECLARE STMT STATEMENT;
  CALL LOGGER.LOG(0, 5, 'Values: ' || VAL);
  PREPARE STMT FROM 'CALL CASCADE(?)';
  EXECUTE STMT USING VAL + 1;
 END @

-- Test fixtures
CREATE OR REPLACE PROCEDURE ONE_TIME_SETUP()
 BEGIN
  -- Empty.
 END @

CREATE OR REPLACE PROCEDURE SETUP()
  BEGIN
  -- Empty.
 END @

CREATE OR REPLACE PROCEDURE TEAR_DOWN()
 BEGIN
  -- Empty.
 END @

CREATE OR REPLACE PROCEDURE ONE_TIME_TEAR_DOWN()
 BEGIN
  CALL LOGGER_1.LOGADMIN.RESET_TABLES();
 END @

-- Tests

-- Test01: Tests message LG0L1.
CREATE OR REPLACE PROCEDURE TEST_01()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'LEVEL_ID should be equal or greater than zero';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (-1, 'NAME');

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test01: Tests message LG0L1', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test02: Tests message LG0L2.
CREATE OR REPLACE PROCEDURE TEST_02()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'LEVEL_ID should be consecutive to the previous maximal '
    || 'value';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (10, 'NAME');

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test02: Tests message LG0L2', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test03: Tests message LG0L3.
CREATE OR REPLACE PROCEDURE TEST_03()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'It is not possible to change the LEVEL_ID';
  UPDATE LOGDATA.LEVELS
    SET LEVEL_ID = 0
    WHERE LEVEL_ID = 1;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test03: Tests message LG0L3', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test04: Tests message LG0L4.
CREATE OR REPLACE PROCEDURE TEST_04()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'Trying to delete the minimal value';
  DELETE FROM LOGDATA.LEVELS
    WHERE LEVEL_ID = 0;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test04: Tests message LG0L4', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test05: Tests message LG0L5.
CREATE OR REPLACE PROCEDURE TEST_05()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'The only possible LEVEL_ID to delete is the maximal '
    || 'value';
  DELETE FROM LOGDATA.LEVELS
    WHERE LEVEL_ID = 1;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test05: Tests message LG0L5', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test06: Tests message LG0C1.
CREATE OR REPLACE PROCEDURE TEST_06()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'ROOT cannot be inserted';
  INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
    VALUES (0, 'ROOT', NULL, 3);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test06: Tests message LG0C1', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test07: Tests message LG0C2.
CREATE OR REPLACE PROCEDURE TEST_07()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'The only logger without parent is ROOT';
  INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
    VALUES (1, 'test7', NULL, 0);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test07: Tests message LG0C2', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test08: Tests message LG0C3.
CREATE OR REPLACE PROCEDURE TEST_08()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'LOGGER_ID cannot be negative';
  INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
    VALUES (-1, 'test8', 0, 5);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test08: Tests message LG0C3', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test09: Tests message LG0C4.
CREATE OR REPLACE PROCEDURE TEST_09()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'The LEVEL_ID is the only column that can be updated';
  UPDATE LOGDATA.CONF_LOGGERS
    SET NAME = 'Test9'
    WHERE LOGGER_ID = 0;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test09: Tests message LG0C4', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test10: Tests message LG0E1.
CREATE OR REPLACE PROCEDURE TEST_10()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'The LEVEL_ID is the only column that can be updated';
  UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
    SET HIERARCHY = ''
    WHERE LOGGER_ID = 0;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test10: Tests message LG0E1', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test11: Tests message LG0E2.
CREATE OR REPLACE PROCEDURE TEST_11()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'ROOT logger cannot be deleted';
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID = 0;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test11: Tests message LG0E2', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test12: Tests message LG0A1.
CREATE OR REPLACE PROCEDURE TEST_12()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'APPENDER_ID for appenders should be greater or equal to '
    || 'zero';
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (-1, 'test12');

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test12: Tests message LG0A1', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test13: Tests message LG0T1.
CREATE OR REPLACE PROCEDURE TEST_13()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'Invalid value for defaultRootLevelId';
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = 'qwerty'
    WHERE KEY = 'defaultRootLevelId';

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test13: Tests message LG0T1', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test14: Tests message LG0F1.
CREATE OR REPLACE PROCEDURE TEST_14()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE VALUE ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'Invalid given parameter: SON_ID';
  SET VALUE = LOGGER.GET_DEFINED_PARENT_LOGGER(NULL);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test14: Tests message LG0F1', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test15: Tests message LG0P1.
CREATE OR REPLACE PROCEDURE TEST_15()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'Invalid given parameter: PARENT or LEVEL';
  CALL LOGGER.MODIFY_DESCENDANTS (NULL, NULL);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test15: Tests message LG0P1', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Test16: Tests message LG001.
CREATE OR REPLACE PROCEDURE TEST_16()
 BEGIN
  DECLARE EXPECTED_MSG VARCHAR(1000);
  DECLARE ACTUAL_MSG VARCHAR(1000) DEFAULT ' ';
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    GET DIAGNOSTICS EXCEPTION 1 ACTUAL_MSG = DB2_TOKEN_STRING;

  SET EXPECTED_MSG = 'Cascade call limit achieved. Log message was written';
  CALL CASCADE(0);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test16: Tests message LG001', EXPECTED_MSG,
    ACTUAL_MSG);
 END@

-- Register the suite.
CALL DB2UNIT.REGISTER_SUITE(CURRENT SCHEMA) @

