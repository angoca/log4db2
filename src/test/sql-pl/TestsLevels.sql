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
 * Tests for the levels table.
 *
 * Version: 2014-04-21 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOG4DB2_LEVELS @

CREATE SCHEMA LOG4DB2_LEVELS @

-- Test fixtures
CREATE OR REPLACE PROCEDURE ONE_TIME_SETUP()
 BEGIN
  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID <> 0;
  UPDATE LOGDATA.CONF_LOGGERS
    SET LEVEL_ID = 0
    WHERE LOGGER_ID = 0;
  DELETE FROM LOGDATA.LEVELS
     WHERE LEVEL_ID = 5;
  DELETE FROM LOGDATA.LEVELS
     WHERE LEVEL_ID = 4;
  DELETE FROM LOGDATA.LEVELS
     WHERE LEVEL_ID = 3;
  DELETE FROM LOGDATA.LEVELS
     WHERE LEVEL_ID = 2;
  DELETE FROM LOGDATA.LEVELS
     WHERE LEVEL_ID = 1;
 END @

CREATE OR REPLACE PROCEDURE SETUP()
 BEGIN
  DELETE FROM LOGDATA.LEVELS
    WHERE LEVEL_ID <> 0;
 END @

CREATE OR REPLACE PROCEDURE TEAR_DOWN()
 BEGIN
  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID <> 0;
  DELETE FROM LOGDATA.LEVELS
    WHERE LEVEL_ID = 3;
  DELETE FROM LOGDATA.LEVELS
    WHERE LEVEL_ID = 2;
  DELETE FROM LOGDATA.LEVELS
    WHERE LEVEL_ID = 1;
 END @

CREATE OR REPLACE PROCEDURE ONE_TIME_TEAR_DOWN()
 BEGIN
  DELETE FROM LOGDATA.LEVELS
    WHERE LEVEL_ID <> 0;
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME)
    VALUES (1, 'fatal');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME)
    VALUES (2, 'error');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME)
    VALUES (3, 'warn');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME)
    VALUES (4, 'info');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME)
    VALUES (5, 'debug');
 END @
 
-- Tests

-- Test01: Inserts a new level.
CREATE OR REPLACE PROCEDURE TEST_01()
 BEGIN
  DECLARE ACTUAL_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE ACTUAL_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;

  SET EXPECTED_LEVEL_ID = 1;
  SET EXPECTED_NAME = 'ON';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID,
    EXPECTED_NAME);
  SELECT LEVEL_ID, NAME INTO ACTUAL_LEVEL_ID, ACTUAL_NAME
    FROM LOGDATA.LEVELS
    WHERE LEVEL_ID <> 0;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test01: Inserts a new level',
    EXPECTED_LEVEL_ID, ACTUAL_LEVEL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test01: Inserts a new level',
    EXPECTED_NAME, ACTUAL_NAME);
 END @

-- Test02: Inserts a new level with null name.
CREATE OR REPLACE PROCEDURE TEST_02()
 BEGIN
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE RAISED_407 BOOLEAN DEFAULT FALSE; -- Null value.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '23502'
    SET RAISED_407 = TRUE;

  SET EXPECTED_LEVEL_ID = 1;
  SET EXPECTED_NAME = NULL;
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID,
    EXPECTED_NAME);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test02: Inserts a new level with null name',
    RAISED_407);
 END @

-- Test03: Inserts a new level with null id.
CREATE OR REPLACE PROCEDURE TEST_03()
 BEGIN
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE RAISED_407 BOOLEAN DEFAULT FALSE; -- Null value.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '23502'
    SET RAISED_407 = TRUE;

  SET EXPECTED_LEVEL_ID = NULL;
  SET EXPECTED_NAME = 'ON';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID,
    EXPECTED_NAME);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test03: Inserts a new level with null id',
    RAISED_407);
 END @

-- Test04: Inserts a new level with negative id.
CREATE OR REPLACE PROCEDURE TEST_04()
 BEGIN
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE RAISED_LG0L1 BOOLEAN DEFAULT FALSE; -- Negative level.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0L1'
    SET RAISED_LG0L1 = TRUE;

  SET EXPECTED_LEVEL_ID = -1;
  SET EXPECTED_NAME = 'test4';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID,
    EXPECTED_NAME);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test04: Inserts a new level with negative '
    || 'id', RAISED_LG0L1);
 END @

-- Test05: Inserts a new level with duplicated 0.
CREATE OR REPLACE PROCEDURE TEST_05()
 BEGIN
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE RAISED_LG0L2 BOOLEAN DEFAULT FALSE; -- Not sequence.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0L2'
    SET RAISED_LG0L2 = TRUE;

  SET EXPECTED_LEVEL_ID = 0;
  SET EXPECTED_NAME = 'test5';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID,
    EXPECTED_NAME);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test05: Inserts a new level with '
    || 'duplicated 0', RAISED_LG0L2);
 END @

-- Test06: Inserts a new level with duplicated id.
CREATE OR REPLACE PROCEDURE TEST_06()
 BEGIN
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE RAISED_LG0L2 BOOLEAN DEFAULT FALSE; -- Not sequence.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0L2'
    SET RAISED_LG0L2 = TRUE;

  SET EXPECTED_LEVEL_ID = 1;
  SET EXPECTED_NAME = 'test6';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID,
    EXPECTED_NAME);
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID,
    EXPECTED_NAME);

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test06: Inserts a new level with '
    || 'duplicated id', RAISED_LG0L2);
 END @

-- Test07: Inserts three level.
CREATE OR REPLACE PROCEDURE TEST_07()
 BEGIN
  DECLARE ACTUAL_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE ACTUAL_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;

  SET EXPECTED_LEVEL_ID = 3;
  SET EXPECTED_NAME = 'C3';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (1, 'A1');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (2, 'B2');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (3, 'C3');
  SELECT LEVEL_ID, NAME INTO ACTUAL_LEVEL_ID, ACTUAL_NAME
    FROM LOGDATA.LEVELS
    WHERE LEVEL_ID = (SELECT MAX(LEVEL_ID) FROM LOGDATA.LEVELS);

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test07: Inserts three level',
    EXPECTED_LEVEL_ID, ACTUAL_LEVEL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test07: Inserts three level',
    EXPECTED_NAME, ACTUAL_NAME);
 END @

-- Test08: Updates a level name.
CREATE OR REPLACE PROCEDURE TEST_08()
 BEGIN
  DECLARE ACTUAL_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE ACTUAL_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;

  SET EXPECTED_LEVEL_ID = 1;
  SET EXPECTED_NAME = 'ON';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, 'on');
  UPDATE LOGDATA.LEVELS
    SET NAME = EXPECTED_NAME
    WHERE LEVEL_ID = EXPECTED_LEVEL_ID;
  SELECT LEVEL_ID, NAME INTO ACTUAL_LEVEL_ID, ACTUAL_NAME
    FROM LOGDATA.LEVELS
    WHERE LEVEL_ID <> 0;

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test08: Updates a level name',
    EXPECTED_LEVEL_ID, ACTUAL_LEVEL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test08: Updates a level name',
    EXPECTED_NAME, ACTUAL_NAME);
 END @

-- Test09: Updates a level id to 0.
CREATE OR REPLACE PROCEDURE TEST_09()
 BEGIN
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE RAISED_LG0L3 BOOLEAN DEFAULT FALSE;
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0L3'
    SET RAISED_LG0L3 = TRUE;

  SET EXPECTED_LEVEL_ID = 1;
  SET EXPECTED_NAME = 'ON';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID,
    EXPECTED_NAME);
  UPDATE LOGDATA.LEVELS
    SET LEVEL_ID = 0
    WHERE LEVEL_ID = EXPECTED_LEVEL_ID;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test09: Updates a id to 0', RAISED_LG0L3);
 END @

-- Test10: Updates a level name.
CREATE OR REPLACE PROCEDURE TEST_10()
 BEGIN
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE CNT SMALLINT;
  DECLARE VALUE BOOLEAN DEFAULT FALSE;

  SET EXPECTED_LEVEL_ID = 2;
  SET EXPECTED_NAME = 'b2';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (1, 'a1');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID,
    EXPECTED_NAME);
  UPDATE LOGDATA.LEVELS
    SET NAME = 'a1'
    WHERE LEVEL_ID = EXPECTED_LEVEL_ID;
  SELECT COUNT(NAME) INTO CNT
    FROM LOGDATA.LEVELS
    WHERE LEVEL_ID <> 0
    GROUP BY NAME;

  -- TODO Remove this variable.
  SET VALUE = CNT <> 2;
  CALL DB2UNIT.ASSERT_BOOLEAN_FALSE('Test10: Updates a name', VALUE);
 END @

-- Test11: Updates a level name to off.
CREATE OR REPLACE PROCEDURE TEST_11()
 BEGIN
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE CNT SMALLINT;
  DECLARE VALUE BOOLEAN DEFAULT FALSE;

  SET EXPECTED_LEVEL_ID = 1;
  SET EXPECTED_NAME = 'off';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, 'a1');
  UPDATE LOGDATA.LEVELS
    SET NAME = EXPECTED_NAME
    WHERE LEVEL_ID = EXPECTED_LEVEL_ID;
  SELECT COUNT(NAME) INTO CNT
    FROM LOGDATA.LEVELS
    WHERE NAME = EXPECTED_NAME
    GROUP BY NAME;

  -- TODO Remove this variable.
  SET VALUE = CNT <> 2;
  CALL DB2UNIT.ASSERT_BOOLEAN_FALSE('Test11: Updates a name to off', VALUE);
 END @

-- Test12: Updates a level id to existant.
CREATE OR REPLACE PROCEDURE TEST_12()
 BEGIN
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE RAISED_LG0L3 BOOLEAN DEFAULT FALSE;
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0L3'
    SET RAISED_LG0L3 = TRUE;

  SET EXPECTED_LEVEL_ID = 2;
  SET EXPECTED_NAME = 'b';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (1, 'a');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID,
    EXPECTED_NAME);
  UPDATE LOGDATA.LEVELS
    SET LEVEL_ID = 1
    WHERE LEVEL_ID = EXPECTED_LEVEL_ID;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test12: Updates a id to existant',
    RAISED_LG0L3);
 END @

-- Test13: Updates a level id to negative.
CREATE OR REPLACE PROCEDURE TEST_13()
 BEGIN
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE RAISED_LG0L3 BOOLEAN DEFAULT FALSE;
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0L3'
    SET RAISED_LG0L3 = TRUE;

  SET EXPECTED_LEVEL_ID = 1;
  SET EXPECTED_NAME = 'ON';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID,
    EXPECTED_NAME);
  UPDATE LOGDATA.LEVELS
    SET LEVEL_ID = -1
    WHERE LEVEL_ID = EXPECTED_LEVEL_ID;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test13: Updates a id to negative',
    RAISED_LG0L3);
 END @

-- Test14: Updates a level id to null.
CREATE OR REPLACE PROCEDURE TEST_14()
 BEGIN
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE RAISED_LG0L3 BOOLEAN DEFAULT FALSE;
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0L3'
    SET RAISED_LG0L3 = TRUE;

  SET EXPECTED_LEVEL_ID = 1;
  SET EXPECTED_NAME = 'ON';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID,
    EXPECTED_NAME);
  UPDATE LOGDATA.LEVELS
    SET LEVEL_ID = NULL
    WHERE LEVEL_ID = EXPECTED_LEVEL_ID;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test14: Updates a id to null',
    RAISED_LG0L3);
 END @

-- Test15: Deletes a level.
CREATE OR REPLACE PROCEDURE TEST_15()
 BEGIN
  DECLARE ACTUAL_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE ACTUAL_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;

  SET EXPECTED_LEVEL_ID = 0;
  SET EXPECTED_NAME = 'off';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (1, 'ON');
  DELETE FROM LOGDATA.LEVELS
    WHERE LEVEL_ID = 1;
  SELECT LEVEL_ID, NAME INTO ACTUAL_LEVEL_ID, ACTUAL_NAME
    FROM LOGDATA.LEVELS
    WHERE LEVEL_ID = (SELECT MAX(LEVEL_ID) FROM LOGDATA.LEVELS);

  CALL DB2UNIT.ASSERT_INT_EQUALS('Test15: Deletes a level',
    EXPECTED_LEVEL_ID, ACTUAL_LEVEL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test15: Deletes a level',
    EXPECTED_NAME, ACTUAL_NAME);
 END @

-- Test16: Deletes a medium level.
CREATE OR REPLACE PROCEDURE TEST_16()
 BEGIN
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE RAISED_LG0L5 BOOLEAN DEFAULT FALSE; -- Delete.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0L5'
    SET RAISED_LG0L5 = TRUE;

  SET EXPECTED_LEVEL_ID = 0;
  SET EXPECTED_NAME = 'off';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (1, 'A1');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (2, 'B2');
  DELETE FROM LOGDATA.LEVELS
    WHERE LEVEL_ID = 1;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test16: Deletes a medium level',
    RAISED_LG0L5);
 END @

-- Test17: Deletes a minimal level.
CREATE OR REPLACE PROCEDURE TEST_17()
 BEGIN
  DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
  DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
  DECLARE RAISED_LG0L4 BOOLEAN DEFAULT FALSE; -- Minimal value.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0L4'
    SET RAISED_LG0L4 = TRUE;

  SET EXPECTED_LEVEL_ID = 0;
  SET EXPECTED_NAME = 'off';
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (1, 'A1');
  INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (2, 'B2');
  DELETE FROM LOGDATA.LEVELS
    WHERE LEVEL_ID = 0;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test17: Deletes a minimal level',
    RAISED_LG0L4);
 END @

