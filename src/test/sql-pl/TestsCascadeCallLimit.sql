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
 * Tests for the cascade call limit. It writes a log when reaching the limit.
 *
 * Version: 2014-04-21 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOG4DB2_CASCADE_CALL_LIMIT @

SET PATH = SYSPROC, LOG4DB2_CASCADE_CALL_LIMIT @

CREATE SCHEMA LOG4DB2_CASCADE_CALL_LIMIT @

-- Test fixtures
CREATE OR REPLACE PROCEDURE ONE_TIME_SETUP()
 BEGIN
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = 5
    WHERE LOGGER_ID = 0;
 END @

CREATE OR REPLACE PROCEDURE SETUP()
 BEGIN
 delete from logs;
  -- Empty
 END @

CREATE OR REPLACE PROCEDURE TEAR_DOWN()
 BEGIN
  -- Empty
 END @

CREATE OR REPLACE PROCEDURE ONE_TIME_TEAR_DOWN()
 BEGIN
  DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
  UPDATE LOGS SET LEVEL_ID = 5 WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved%';
  UPDATE LOGS SET LEVEL_ID = 5 WHERE MESSAGE LIKE 'ROOT - Cascade call for "LOGGING" enters with ';
 END @

-- Install

-- 56 or 57 for test 02, 06, 14, 18, 23, 24
CREATE VARIABLE VAL_56_57 SMALLINT CONSTANT 56 @
-- 56-58 for test 10
CREATE VARIABLE VAL_56_58 SMALLINT CONSTANT 56 @
-- 58 for test 03, 07, 11, 15, 19
CREATE VARIABLE VAL_58A SMALLINT CONSTANT 58 @
-- 58 for test 05, 09, 13, 17
CREATE VARIABLE VAL_58B SMALLINT CONSTANT 58 @
-- 57 or 58 for test 21
CREATE VARIABLE VAL_57_58 SMALLINT CONSTANT 57 @
-- 59 ... for test 04, 08, 12, 16, 20, 22
CREATE VARIABLE MIN_59 SMALLINT CONSTANT 59 @

CREATE OR REPLACE PROCEDURE LOGGING (
  IN VAL SMALLINT,
  IN LEVEL SMALLINT,
  IN LIMIT SMALLINT)
 BEGIN
  DECLARE MESSAGE ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE STMT STATEMENT;

  IF (VAL >= LIMIT) THEN
   CASE LEVEL
    WHEN 1 THEN
     CALL LOGGER.FATAL(0, 'Cascade call for "LOGGING" enters with ' || COALESCE(VAL, -1));
    WHEN 2 THEN
     CALL LOGGER.ERROR(0, 'Cascade call for "LOGGING" enters with ' || COALESCE(VAL, -1));
    WHEN 3 THEN
     CALL LOGGER.WARN(0, 'Cascade call for "LOGGING" enters with ' || COALESCE(VAL, -1));
    WHEN 4 THEN
     CALL LOGGER.INFO(0, 'Cascade call for "LOGGING" enters with ' || COALESCE(VAL, -1));
    WHEN 5 THEN
     CALL LOGGER.DEBUG(0, 'Cascade call for "LOGGING" enters with ' || COALESCE(VAL, -1));
    ELSE
     CALL LOGGER.LOG(0, 3, 'Cascade call for "LOGGING" enters with ' || COALESCE(VAL, -1));
    END CASE;
   COMMIT;
  ELSE
   PREPARE STMT FROM 'CALL LOGGING(?, ?, ?)';
   EXECUTE STMT USING VAL + 1, LEVEL, LIMIT;
  END IF;
 END @

-- TODO The same with a function.

--Tests

-- Test01: Limit logging to ROOT with fatal.
CREATE OR REPLACE PROCEDURE TEST_01()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    BEGIN END;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_58B;
  CALL LOGGING(1, 1, CASCADE);
  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE = 'LG001. Cascade call limit achieved, for FATAL: (0) '
    || 'Cascade call for "LOGGING" enters with ' || CASCADE
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test01: Limit logging to ROOT with fatal',
    EXPECTED, ACTUAL);
 END @

-- Test02: Limit achieved logging to ROOT with fatal.
CREATE OR REPLACE PROCEDURE TEST_02()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE RAISED_LG001 BOOLEAN DEFAULT FALSE; -- Just one ROOT.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    SET RAISED_LG001 = TRUE;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_56_57;
  CALL LOGGING(1, 1, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test02: Limit achieved to ROOT with fatal',
    RAISED_LG001);

  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for LOG: Cascade '
    || 'call for "LOGGING" enters with ' || CASCADE
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS)
    ;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test02: Limit achieved to ROOT with fatal',
    EXPECTED, ACTUAL);
 END @

-- Test03: Limit passed logging to ROOT with fatal.
CREATE OR REPLACE PROCEDURE TEST_03()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE RAISED_LG001 BOOLEAN DEFAULT FALSE; -- Just one ROOT.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    SET RAISED_LG001 = TRUE;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_58A;
  CALL LOGGING(1, 1, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test03: Limit passed to ROOT with fatal',
    RAISED_LG001);

  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for FATAL: (0) '
    || 'Cascade call for "LOGGING" en%'
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test03: Limit passed to ROOT with fatal',
    EXPECTED, ACTUAL);
  DELETE FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieve, for %';
 END @

-- Test04: Cascade call limit with fatal.
CREATE OR REPLACE PROCEDURE TEST_04()
 BEGIN
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE RAISED_724 BOOLEAN DEFAULT FALSE; -- Null value.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '54038'
    SET RAISED_724 = TRUE;

  SET CASCADE = MIN_59;
  CALL LOGGING(1, 1, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test04: Cascade call limit with fatal',
    RAISED_724);
 END @

-- Test05: Limit logging to ROOT with error.
CREATE OR REPLACE PROCEDURE TEST_05()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    BEGIN END;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_58B;
  CALL LOGGING(1, 2, CASCADE);
  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE = 'LG001. Cascade call limit achieved, for ERROR: (0) '
    || 'Cascade call for "LOGGING" enters with ' || CASCADE
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test05: Limit logging to ROOT with error',
    EXPECTED, ACTUAL);
 END @

-- Test06: Limit achieved logging to ROOT with error.
CREATE OR REPLACE PROCEDURE TEST_06()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE RAISED_LG001 BOOLEAN DEFAULT FALSE; -- Just one ROOT.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    SET RAISED_LG001 = TRUE;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_56_57;
  CALL LOGGING(1, 2, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test06: Limit achieved to ROOT with error',
    RAISED_LG001);

  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for LOG: Cascade '
    || 'call for "LOGGING" enters w%'
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS)
    AND LEVEL_ID = 2;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test06: Limit achieved to ROOT with error',
    EXPECTED, ACTUAL);
 END @

-- Test07: Limit passed logging to ROOT with error.
CREATE OR REPLACE PROCEDURE TEST_07()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE RAISED_LG001 BOOLEAN DEFAULT FALSE; -- Just one ROOT.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    SET RAISED_LG001 = TRUE;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_58A;
  CALL LOGGING(1, 2, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test07: Limit passed to ROOT with error',
    RAISED_LG001);

  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for ERROR: (0) '
    || 'Cascade call for "LOGGING" en%'
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test07: Limit passed to ROOT with error',
    EXPECTED, ACTUAL);
  DELETE FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieve, for %';
 END @

-- Test08: Cascade call limit with error.
CREATE OR REPLACE PROCEDURE TEST_08()
 BEGIN
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE RAISED_724 BOOLEAN DEFAULT FALSE; -- Null value.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '54038'
    SET RAISED_724 = TRUE;

  SET CASCADE = MIN_59;
  CALL LOGGING(1, 2, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test08: Cascade call limit with error',
    RAISED_724);
 END @

-- Test09: Limit logging to ROOT with warn.
CREATE OR REPLACE PROCEDURE TEST_09()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    BEGIN END;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_58B;
  CALL LOGGING(1, 3, CASCADE);
  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE = 'LG001. Cascade call limit achieved, for WARN: (0) Cascade '
    || 'call for "LOGGING" enters with ' || CASCADE
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test09: Limit logging to ROOT with warn',
    EXPECTED, ACTUAL);
 END @

-- Test10: Limit achieved logging to ROOT with warn.
CREATE OR REPLACE PROCEDURE TEST_10()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE RAISED_LG001 BOOLEAN DEFAULT FALSE; -- Just one ROOT.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    SET RAISED_LG001 = TRUE;

  SET CASCADE = VAL_56_58;
  CALL LOGGING(1, 3, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test10: Limit achieved to ROOT with warn',
    RAISED_LG001);

  SET RAISED_LG001 = FALSE;
  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for LOG: Cascade '
    || 'call for "LOGGING" enters w%'
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS)
    AND LEVEL_ID = 3;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test10: Limit achieved to ROOT with warn',
    EXPECTED, ACTUAL);
 END @

-- Test11: Limit passed logging to ROOT with warn.
CREATE OR REPLACE PROCEDURE TEST_11()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE RAISED_LG001 BOOLEAN DEFAULT FALSE; -- Just one ROOT.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    SET RAISED_LG001 = TRUE;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_58A;
  CALL LOGGING(1, 3, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test11: Limit passed to ROOT with warn',
    RAISED_LG001);

  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for WARN: (0) '
    || 'Cascade call for "LOGGING" en%'
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test11: Limit passed to ROOT with warn',
    EXPECTED, ACTUAL);
  DELETE FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieve, for %';
 END @

-- Test12: Cascade call limit with warn.
CREATE OR REPLACE PROCEDURE TEST_12()
 BEGIN
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE RAISED_724 BOOLEAN DEFAULT FALSE; -- Null value.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '54038'
    SET RAISED_724 = TRUE;

  SET CASCADE = MIN_59;
  CALL LOGGING(1, 3, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test12: Cascade call limit with warn',
    RAISED_724);
 END @

-- Test13: Limit logging to ROOT with info.
CREATE OR REPLACE PROCEDURE TEST_13()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    BEGIN END;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_58B;
  CALL LOGGING(1, 4, CASCADE);
  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE = 'LG001. Cascade call limit achieved, for INFO: (0) Cascade '
    || 'call for "LOGGING" enters with ' || CASCADE
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test13: Limit logging to ROOT with info',
    EXPECTED, ACTUAL);
 END @

-- Test14: Limit achieved logging to ROOT with info.
CREATE OR REPLACE PROCEDURE TEST_14()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE RAISED_LG001 BOOLEAN DEFAULT FALSE; -- Just one ROOT.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    SET RAISED_LG001 = TRUE;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_56_57;
  CALL LOGGING(1, 4, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test14: Limit achieved to ROOT with info',
    RAISED_LG001);

  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for LOG: Cascade '
    || 'call for "LOGGING" enters w%'
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test14: Limit achieved to ROOT with info',
    EXPECTED, ACTUAL);
 END @

-- Test15: Limit passed logging to ROOT with info.
CREATE OR REPLACE PROCEDURE TEST_15()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE RAISED_LG001 BOOLEAN DEFAULT FALSE; -- Just one ROOT.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    SET RAISED_LG001 = TRUE;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_58A;
  CALL LOGGING(1, 4, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test15: Limit passed to ROOT with info',
    RAISED_LG001);

  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for INFO: (0) '
    || 'Cascade call for "LOGGING" en%'
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test15: Limit passed to ROOT with info',
    EXPECTED, ACTUAL);
  DELETE FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieve, for %';
 END @

-- Test16: Cascade call limit with info.
CREATE OR REPLACE PROCEDURE TEST_16()
 BEGIN
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE RAISED_724 BOOLEAN DEFAULT FALSE; -- Null value.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '54038'
    SET RAISED_724 = TRUE;

  SET CASCADE = MIN_59;
  CALL LOGGING(1, 4, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test16: Cascade call limit with info',
    RAISED_724);
 END @

-- Test17: Limit logging to ROOT with debug.
CREATE OR REPLACE PROCEDURE TEST_17()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    BEGIN END;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_58B;
  CALL LOGGING(1, 5, CASCADE);
  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE = 'LG001. Cascade call limit achieved, for DEBUG: (0) '
    || 'Cascade call for "LOGGING" enters with ' || CASCADE
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test17: Limit logging to ROOT with debug',
    EXPECTED, ACTUAL);
 END @

-- Test18: Limit achieved logging to ROOT with debug.
CREATE OR REPLACE PROCEDURE TEST_18()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE RAISED_LG001 BOOLEAN DEFAULT FALSE; -- Just one ROOT.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    SET RAISED_LG001 = TRUE;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_56_57;
  CALL LOGGING(1, 5, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test18: Limit achieved to ROOT with debug',
    RAISED_LG001);

  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for LOG: Cascade '
    || 'call for "LOGGING" enters w%'
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test18: Limit achieved to ROOT with debug',
    EXPECTED, ACTUAL);
 END @

-- Test19: Limit passed logging to ROOT with debug.
CREATE OR REPLACE PROCEDURE TEST_19()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE RAISED_LG001 BOOLEAN DEFAULT FALSE; -- Just one ROOT.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    SET RAISED_LG001 = TRUE;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_58A;
  CALL LOGGING(1, 5, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test19: Limit passed to ROOT with debug',
    RAISED_LG001);

  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for DEBUG: (0) '
    || 'Cascade call for "LOGGING" en%'
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test19: Limit passed to ROOT with debug',
    EXPECTED, ACTUAL);
  DELETE FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieve, for %';
 END @

-- Test20: Cascade call limit with debug.
CREATE OR REPLACE PROCEDURE TEST_20()
 BEGIN
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE RAISED_724 BOOLEAN DEFAULT FALSE; -- Null value.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '54038'
    SET RAISED_724 = TRUE;

  SET CASCADE = MIN_59;
  CALL LOGGING(1, 5, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test20: Cascade call limit with debug',
    RAISED_724);
 END @

-- Test21: Limit passed logging to ROOT with default.
CREATE OR REPLACE PROCEDURE TEST_22()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE RAISED_LG001 BOOLEAN DEFAULT FALSE; -- Just one ROOT.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    SET RAISED_LG001 = TRUE;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_57_58;
  CALL LOGGING(1, -1, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test21: Limit passed to ROOT with default',
    RAISED_LG001);

  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for LOG: Cascade '
    || 'call for "LOGGING" enters w%'
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test21: Limit passed to ROOT with default',
    EXPECTED, ACTUAL);
  DELETE FROM LOGS
    WHERE MESSAGE LIKE 'LG001. Cascade call limit achieve, for %';
 END @

-- Test22: Cascade call limit with default.
CREATE OR REPLACE PROCEDURE TEST_23()
 BEGIN
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE RAISED_724 BOOLEAN DEFAULT FALSE; -- Null value.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '54038'
    SET RAISED_724 = TRUE;

  SET CASCADE = MIN_59;
  CALL LOGGING(1, -1, CASCADE);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test22: Cascade call limit with default',
    RAISED_724);
 END @

-- Test23: Limit logging to ROOT  56 - 57.
CREATE OR REPLACE PROCEDURE TEST_24()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    BEGIN END;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_56_57;
  CALL LOGGING(1, 1, CASCADE);
  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE = 'LG001. Cascade call limit achieved, for LOG: Cascade call '
    || 'for "LOGGING" enters with ' || CASCADE
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test23: Limit logging to ROOT 60',
    EXPECTED, ACTUAL);
 END @

-- Test24: Limit logging to ROOT 56 - 57.
CREATE OR REPLACE PROCEDURE TEST_25()
 BEGIN
  DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CASCADE SMALLINT; -- Cascade calls.
  DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
    BEGIN END;

  SET EXPECTED = 'TRUE';
  SET CASCADE = VAL_56_57;
  CALL LOGGING(1, 1, CASCADE);
  SELECT 'TRUE' INTO ACTUAL
    FROM LOGS
    WHERE MESSAGE = 'LG001. Cascade call limit achieved, for LOG: Cascade call '
    || 'for "LOGGING" enters with ' || CASCADE
    AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test24: Limit logging to ROOT 61',
    EXPECTED, ACTUAL);
 END @

