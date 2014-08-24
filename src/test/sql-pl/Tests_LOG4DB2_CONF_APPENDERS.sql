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
 * Tests for the conf_appenders table.
 *
 * Version: 2014-04-21 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOG4DB2_CONF_APPENDERS @

CREATE SCHEMA LOG4DB2_CONF_APPENDERS @

-- Test fixtures
CREATE OR REPLACE PROCEDURE ONE_TIME_SETUP()
 P_ONE_TIME_SETUP: BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;

  SELECT REF_ID INTO ID FROM FINAL TABLE (
    INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
    ('test1', 1, '%m'));
  DELETE FROM LOGDATA.CONF_APPENDERS;
 END P_ONE_TIME_SETUP @

CREATE OR REPLACE PROCEDURE SETUP()
 P_SETUP: BEGIN
  -- Empty
 END P_SETUP @

CREATE OR REPLACE PROCEDURE TEAR_DOWN()
 P_TEAR_DOWN: BEGIN
  DELETE FROM LOGDATA.CONF_APPENDERS;
 END P_TEAR_DOWN @

CREATE OR REPLACE PROCEDURE ONE_TIME_TEAR_DOWN()
 P_ONE_TIME_TEAR_DOWN: BEGIN
  DELETE FROM LOGDATA.CONF_APPENDERS;
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION,
    PATTERN)
    VALUES ('Tables', 1, NULL, '[%p] %c -%T%m');
 END P_ONE_TIME_TEAR_DOWN @

-- Tests

-- Test01: Inserts a normal appender_ref configuration.
CREATE OR REPLACE PROCEDURE TEST_01()
 BEGIN
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
    ('test1', 1, '%m');
 END@

-- Test02: Inserts an appender_ref with null appender_id.
CREATE OR REPLACE PROCEDURE TEST_02()
 BEGIN
  DECLARE RAISED_407 BOOLEAN; -- Not null.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '23502'
    SET RAISED_407 = TRUE;

  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
    ('test2', NULL, '%m');

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test02: Inserts with null appender_id',
    RAISED_407);
 END@

-- Test03: Inserts an appender_ref with inexistent appender_id.
CREATE OR REPLACE PROCEDURE TEST_03()
 BEGIN
  DECLARE RAISED_530 BOOLEAN; -- Foreign key.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '23503'
    SET RAISED_530 = TRUE;

  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
    ('test3', 32000, '%m');

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test03: Inserts with inexistent',
    RAISED_530);
 END@

-- Test04: Inserts an appender_ref with id.
CREATE OR REPLACE PROCEDURE TEST_04()
 BEGIN
  DECLARE STMT VARCHAR(256);
  DECLARE PREP STATEMENT;

  SET STMT = 'INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, '
    || 'PATTERN) VALUES (1, ''test4'', 1, ''%m'')';
  PREPARE PREP FROM STMT;
  EXECUTE PREP;
 END@

-- Test05: Inserts an appender_ref with negative id.
CREATE OR REPLACE PROCEDURE TEST_05()
 BEGIN
  DECLARE STMT VARCHAR(256);
  DECLARE PREP STATEMENT;

  SET STMT = 'INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, '
    || 'PATTERN) VALUES (-1, ''test4'', 1, ''%m'')';
  PREPARE PREP FROM STMT;
  EXECUTE PREP;
 END@

-- Test06: Inserts an appender_ref with null id.
CREATE OR REPLACE PROCEDURE TEST_06()
 BEGIN
  DECLARE STMT VARCHAR(256);
  DECLARE RAISED_407 BOOLEAN; -- Not null.
  DECLARE PREP STATEMENT;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '23502'
    SET RAISED_407 = TRUE;

  SET STMT = 'INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, '
    || 'PATTERN) VALUES (NULL, ''test6'', 1, ''%m'')';
  PREPARE PREP FROM STMT;
  EXECUTE PREP;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test06: Inserts with null id',
    RAISED_407);
 END@

-- Test07: Updates an appender_ref with null appender_id.
CREATE OR REPLACE PROCEDURE TEST_07()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE RAISED_407 BOOLEAN; -- Not null.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '23502'
    SET RAISED_407 = TRUE;

  SELECT REF_ID INTO ID FROM FINAL TABLE (
    INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
    ('test7', 1, '%m'));
  UPDATE LOGDATA.CONF_APPENDERS
    SET APPENDER_ID = NULL
    WHERE REF_ID = ID;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test07: Updates with null appender_id',
    RAISED_407);
 END@

-- Test08: Updates an appender with inexistant appender_id.
CREATE OR REPLACE PROCEDURE TEST_08()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE RAISED_530 BOOLEAN; -- Foreign key.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '23503'
    SET RAISED_530 = TRUE;

  SELECT REF_ID INTO ID FROM FINAL TABLE (
    INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
    ('test8', 1, '%m'));
  UPDATE LOGDATA.CONF_APPENDERS
    SET APPENDER_ID = 32000
    WHERE REF_ID = ID;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test08: Updates with inexistant app_id',
    RAISED_530);
 END@

-- Test09: Updates an appender_ref with negative id.
CREATE OR REPLACE PROCEDURE TEST_09()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE STMT VARCHAR(256);
  DECLARE PREP STATEMENT;

  SELECT REF_ID INTO ID FROM FINAL TABLE (
    INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
    ('test9', 1, '%m'));
  SET STMT = 'UPDATE LOGDATA.CONF_APPENDERS SET REF_ID = -2 WHERE REF_ID = '
    || ID;
  PREPARE PREP FROM STMT;
  EXECUTE PREP;
 END@

-- Test10: Updates an appender_ref with null id.
CREATE OR REPLACE PROCEDURE TEST_10()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
  DECLARE STMT VARCHAR(256);
  DECLARE RAISED_407 BOOLEAN; -- Not null.
  DECLARE PREP STATEMENT;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '23502'
    SET RAISED_407 = TRUE;

  SELECT REF_ID INTO ID FROM FINAL TABLE (
    INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
    ('test10', 1, '%m'));
  SET STMT = 'UPDATE LOGDATA.CONF_APPENDERS SET REF_ID = NULL WHERE REF_ID = '
    || ID;
  PREPARE PREP FROM STMT;
  EXECUTE PREP;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test10: Updates an appender_ref with null '
    || 'id', RAISED_407);
 END@

-- Test11: Updates an appender_ref normally.
CREATE OR REPLACE PROCEDURE TEST_11()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;

  SELECT REF_ID INTO ID FROM FINAL TABLE (
    INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION,
    PATTERN) VALUES ('test11', 1, NULL, '%m'));
  UPDATE LOGDATA.CONF_APPENDERS
    SET NAME = 'TEST10', PATTERN = ' --%m-- '
    WHERE REF_ID = ID;
 END@

-- Test12: Deletes an appender.
CREATE OR REPLACE PROCEDURE TEST_12()
 BEGIN
  DECLARE ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;

  SELECT REF_ID INTO ID FROM FINAL TABLE (
    INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
    ('test12', 1, '%m'));
  DELETE FROM LOGDATA.CONF_APPENDERS
    WHERE REF_ID = ID;
 END@

-- Test13: Deletes all appenders.
CREATE OR REPLACE PROCEDURE TEST_13()
 BEGIN
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
    ('test13', 1, '%m');
  DELETE FROM LOGDATA.CONF_APPENDERS;
 END@

-- Test14: Inserts a normal appender_ref configuration with a level.
CREATE OR REPLACE PROCEDURE TEST_14()
 BEGIN
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN, LEVEL_ID)
    VALUES ('test1', 1, '%m', 2);
 END@

-- Test15: Inserts a normal appender_ref configuration with a null level.
CREATE OR REPLACE PROCEDURE TEST_15()
 BEGIN
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN, LEVEL_ID)
    VALUES ('test1', 1, '%m', null);
 END@

-- Register the suite.
CALL DB2UNIT.REGISTER_SUITE(CURRENT SCHEMA) @

