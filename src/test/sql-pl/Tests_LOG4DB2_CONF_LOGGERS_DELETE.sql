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
 * Tests for the logger's suppresion (conf_logger table).
 *
 * Version: 2014-04-21 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOG4DB2_CONF_LOGGERS_DELETE @

CREATE SCHEMA LOG4DB2_CONF_LOGGERS_DELETE @

SET PATH = LOG4DB2_CONF_LOGGERS_DELETE, LOGGER_1RC @

CREATE OR REPLACE PROCEDURE DELETE_LAST_MESSAGE_FROM_TRIGGER()
 BEGIN
  DECLARE MAX_DATE ANCHOR LOGDATA.LOGS.DATE;

  SELECT MAX(DATE) INTO MAX_DATE FROM LOGDATA.LOGS;
  DELETE FROM LOGDATA.LOGS
    WHERE MESSAGE = 'A manual CONF_LOGGERS_EFFECTIVE update should be realized.'
    AND DATE = MAX_DATE;
  UPDATE LOGDATA.CONF_LOGGERS SET LEVEL_ID = 0 WHERE LOGGER_ID = 0;
 END @

-- Test fixtures
CREATE OR REPLACE PROCEDURE ONE_TIME_SETUP()
 BEGIN
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = '3'
    WHERE KEY = 'defaultRootLevelId';
  CALL DELETE_LAST_MESSAGE_FROM_TRIGGER();
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = 'false'
    WHERE KEY = 'internalCache';
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = 'false'
    WHERE KEY = 'logInternals';
 END @

CREATE OR REPLACE PROCEDURE SETUP()
 BEGIN
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
 END @

CREATE OR REPLACE PROCEDURE TEAR_DOWN()
 BEGIN
  -- Empty
 END @

CREATE OR REPLACE PROCEDURE ONE_TIME_TEAR_DOWN()
 BEGIN
  DELETE FROM LOGDATA.CONFIGURATION;
  INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE)
    VALUES ('autonomousLogging', 'true'),
           ('defaultRootLevelId', '3'),
           ('internalCache', 'true'),
           ('logInternals', 'false'),
           ('secondsToRefresh', '30');
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
 END @

-- Install

CREATE OR REPLACE FUNCTION GET_MAX_ID(
  ) RETURNS ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
 BEGIN
  DECLARE RET ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  SET RET = (SELECT MAX(LOGGER_ID)
    FROM LOGDATA.CONF_LOGGERS);
  RETURN RET;
 END@

-- Tests

-- Test01: Tests to delete ROOT logger with a given level.
CREATE OR REPLACE PROCEDURE TEST_01()
 BEGIN
  DECLARE EXPECTED_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE ACTUAL_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE RAISED_LG0E2 BOOLEAN DEFAULT FALSE; -- For a controlled error.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0E2'
    SET RAISED_LG0E2 = TRUE;

  SET EXPECTED_LEVEL = 5;
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = EXPECTED_LEVEL
    WHERE LOGGER_ID = 0;
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID = 0;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test01: Tests to delete ROOT logger with a '
    || 'given level', RAISED_LG0E2);

 SELECT LEVEL_ID INTO ACTUAL_LEVEL
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE LOGGER_ID = 0;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test01: Tests to delete ROOT logger with a '
    || 'given level', EXPECTED_LEVEL, ACTUAL_LEVEL);
 END @

-- Test02: Tests to delete ROOT logger with null level.
CREATE OR REPLACE PROCEDURE TEST_02()
 BEGIN
  DECLARE EXPECTED_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE ACTUAL_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE RAISED_LG0E2 BOOLEAN DEFAULT FALSE; -- For a controlled error.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0E2'
    SET RAISED_LG0E2 = TRUE;

  SET EXPECTED_LEVEL = CAST(LOGGER.GET_VALUE('defaultRootLevelId') AS SMALLINT);
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = NULL
    WHERE LOGGER_ID = 0;
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID = 0;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test02: Tests to delete ROOT logger with '
    || 'null level', RAISED_LG0E2);

  SELECT LEVEL_ID INTO ACTUAL_LEVEL
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE LOGGER_ID = 0;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test02: Tests to delete ROOT logger with '
    || 'null level', EXPECTED_LEVEL, ACTUAL_LEVEL);
 END @

-- Test03: Tests to delete all inserted loggers.
CREATE OR REPLACE PROCEDURE TEST_03()
 BEGIN
  DECLARE EXPECTED_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE ACTUAL_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE MAX_ID ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_QTY SMALLINT;
  DECLARE ACTUAL_QTY SMALLINT;
  DECLARE RAISED_LG0E2 BOOLEAN DEFAULT FALSE; -- For a controlled error.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0E2'
    SET RAISED_LG0E2 = TRUE;

  INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
    VALUES ('T3', 0, 0);
  SET MAX_ID = GET_MAX_ID();
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;

  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = '4'
    WHERE KEY = 'defaultRootLevelId';
  CALL DELETE_LAST_MESSAGE_FROM_TRIGGER();
  CALL LOGGER.REFRESH_CACHE();

  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = 5
    WHERE LOGGER_ID = 0;

  INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
    VALUES ('Test3', 0, 3);
  SET EXPECTED_QTY = 6; -- db2unit loggers
  DELETE FROM LOGDATA.CONF_LOGGERS;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test03a: Tests to delete all inserted '
    || 'loggers', RAISED_LG0E2);

  SELECT COUNT(1) INTO ACTUAL_QTY
    FROM LOGDATA.CONF_LOGGERS;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test03b: Tests to delete all inserted '
    || 'loggers', EXPECTED_QTY, ACTUAL_QTY);

  SET EXPECTED_LEVEL = 3;
  SELECT LEVEL_ID INTO ACTUAL_LEVEL
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE LOGGER_ID = MAX_ID + 1;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test03c: Tests to delete all inserted '
    || 'loggers', EXPECTED_LEVEL, ACTUAL_LEVEL);

  SET EXPECTED_LEVEL = 5;
  SELECT LEVEL_ID INTO ACTUAL_LEVEL
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE LOGGER_ID = 0;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test03d: Tests to delete all inserted '
    || 'loggers', EXPECTED_LEVEL, ACTUAL_LEVEL);
 END @

-- Test04: Tests to delete all null inserted loggers.
CREATE OR REPLACE PROCEDURE TEST_04()
 BEGIN
  DECLARE EXPECTED_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE ACTUAL_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE MAX_ID ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_QTY SMALLINT;
  DECLARE ACTUAL_QTY SMALLINT;
  DECLARE RAISED_LG0E2 BOOLEAN DEFAULT FALSE; -- For a controlled error.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0E2'
    SET RAISED_LG0E2 = TRUE;

  INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
    VALUES ('T4', 0, 0);
  SET MAX_ID = GET_MAX_ID();
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;

  SET EXPECTED_LEVEL = 2;
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = EXPECTED_LEVEL
    WHERE LOGGER_ID = 0;

  INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
    VALUES ('Test40', 0, NULL);
  SET EXPECTED_QTY = 6; -- db2unit loggers.
  DELETE FROM LOGDATA.CONF_LOGGERS;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test04a: Tests to delete all null inserted '
    || 'logger', RAISED_LG0E2);

  SELECT COUNT(1) INTO ACTUAL_QTY
    FROM LOGDATA.CONF_LOGGERS;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test04b: Tests to delete all null inserted '
    || 'logger', EXPECTED_QTY, ACTUAL_QTY);

  SELECT LEVEL_ID INTO ACTUAL_LEVEL
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE LOGGER_ID = MAX_ID + 1;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test04c: Tests to delete all null inserted '
    || 'logger', EXPECTED_LEVEL, ACTUAL_LEVEL);

  SELECT LEVEL_ID INTO ACTUAL_LEVEL
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE LOGGER_ID = 0;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test04d: Tests to delete all null inserted '
    || 'logger', EXPECTED_LEVEL, ACTUAL_LEVEL);
 END @

-- Test05: Tests to delete inserted logger.
CREATE OR REPLACE PROCEDURE TEST_05()
 BEGIN
  DECLARE EXPECTED_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE ACTUAL_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_QTY SMALLINT;
  DECLARE ACTUAL_QTY SMALLINT;
  DECLARE MAX_ID ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;

  INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
    VALUES ('T5', 0, 0);
  SET MAX_ID = GET_MAX_ID();
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;

  SET EXPECTED_QTY = 0;
  SET EXPECTED_LEVEL = NULL;
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = 5
    WHERE LOGGER_ID = 0;
  INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
    VALUES ('Test5', 0, 3);
  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID = MAX_ID + 1;
  SELECT COUNT(1) INTO ACTUAL_QTY
    FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID = MAX_ID + 1;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test05: Tests to delete inserted logger',
    EXPECTED_QTY, ACTUAL_QTY);

  SET EXPECTED_LEVEL = 5;
  SELECT LEVEL_ID INTO ACTUAL_LEVEL
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE LOGGER_ID = 0;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test05: Tests to delete inserted logger',
    EXPECTED_LEVEL, ACTUAL_LEVEL);
 END @

-- Test06: Tests to delete null inserted logger.
CREATE OR REPLACE PROCEDURE TEST_06()
 BEGIN
  DECLARE EXPECTED_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE ACTUAL_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_QTY SMALLINT;
  DECLARE ACTUAL_QTY SMALLINT;
  DECLARE MAX_ID ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
    VALUES ('T6', 0, 0);
  SET MAX_ID = GET_MAX_ID();
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;

  SET EXPECTED_QTY = 0;
  SET EXPECTED_LEVEL = NULL;
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = 2
    WHERE LOGGER_ID = 0;
  INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
    VALUES ('Test6', 0, NULL);
  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID = MAX_ID + 1;
  SELECT COUNT(1) INTO ACTUAL_QTY
    FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID = MAX_ID + 1;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test06: Tests to delete null inserted logger',
    EXPECTED_QTY, ACTUAL_QTY);

  SELECT LEVEL_ID INTO ACTUAL_LEVEL
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE LOGGER_ID = MAX_ID + 1;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test06: Tests to delete null inserted logger',
    EXPECTED_LEVEL, ACTUAL_LEVEL);

  SET EXPECTED_LEVEL = 2;
  SELECT LEVEL_ID INTO ACTUAL_LEVEL
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE LOGGER_ID = 0;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test06: Tests to delete null inserted logger',
    EXPECTED_LEVEL, ACTUAL_LEVEL);
 END @

-- Test07: Tests to delete ROOT logger cascade.
CREATE OR REPLACE PROCEDURE TEST_07()
 BEGIN
  DECLARE RAISED_LG0E2 BOOLEAN DEFAULT FALSE; -- For a controlled error.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0E2'
    SET RAISED_LG0E2 = TRUE;

  INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
    VALUES ('T7', 0, 0);
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = '3'
    WHERE KEY = 'defaultRootLevelId';
  CALL LOGGER.REFRESH_CACHE();
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = 1
    WHERE LOGGER_ID = 0;
  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE NAME = 'ROOT';

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test07: Tests to delete ROOT logger '
    || 'cascade', RAISED_LG0E2);
 END @

-- Test08: Tests to delete a logger cascade.
CREATE OR REPLACE PROCEDURE TEST_08()
 BEGIN
  DECLARE EXPECTED_QTY SMALLINT;
  DECLARE ACTUAL_QTY SMALLINT;
  DECLARE MAX_ID ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SELECT COUNT(1) INTO EXPECTED_QTY
    FROM LOGDATA.CONF_LOGGERS;
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = 2
    WHERE LOGGER_ID = 0;
  INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
    VALUES ('Test8a', 0, 1);
  SET MAX_ID = GET_MAX_ID();
  INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
    VALUES ('Test8b', MAX_ID, 2);
  SET MAX_ID = GET_MAX_ID();
  INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
    VALUES ('Test8c', MAX_ID, 4);
  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE NAME = 'Test8a';
  SELECT COUNT(1) INTO ACTUAL_QTY
    FROM LOGDATA.CONF_LOGGERS;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test08: Tests to delete a logger cascade',
    EXPECTED_QTY, ACTUAL_QTY);
 END @

-- Register the suite.
CALL DB2UNIT.REGISTER_SUITE(CURRENT SCHEMA) @
