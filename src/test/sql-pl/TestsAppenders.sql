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
 * Tests for the appenders table.
 *
 * Version: 2014-04-21 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOG4DB2_APPENDERS @

CREATE SCHEMA LOG4DB2_APPENDERS @

-- Test fixtures
CREATE OR REPLACE PROCEDURE ONE_TIME_SETUP()
 P_ONE_TIME_SETUP: BEGIN
  DELETE FROM LOGDATA.APPENDERS;
 END P_ONE_TIME_SETUP @

CREATE OR REPLACE PROCEDURE SETUP()
 P_SETUP: BEGIN
  -- Empty
 END P_SETUP @

CREATE OR REPLACE PROCEDURE TEAR_DOWN()
 P_TEAR_DOWN: BEGIN
  -- Empty
 END P_TEAR_DOWN @

CREATE OR REPLACE PROCEDURE ONE_TIME_TEAR_DOWN()
 P_ONE_TIME_TEAR_DOWN: BEGIN
  DELETE FROM LOGDATA.APPENDERS;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME)
    VALUES (1, 'Tables');
  INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, CONFIGURATION,
    PATTERN)
    VALUES (1, 'Tables', 1, NULL, '[%p] %c - %m');
  INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
    VALUES (0, 1);
 END P_ONE_TIME_TEAR_DOWN @

-- Tests

-- Test01: Inserts a normal appender configuration.
CREATE OR REPLACE PROCEDURE TEST_01()
 BEGIN
  DELETE FROM LOGDATA.APPENDERS;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (1, 'test1');
 END@

-- Test02: Inserts an appender with null appender_id.
CREATE OR REPLACE PROCEDURE TEST_02()
 BEGIN
  DECLARE RAISED_407 BOOLEAN; -- Not null.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '23502'
    SET RAISED_407 = TRUE;

  DELETE FROM LOGDATA.APPENDERS;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (NULL, 'test2');

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test02: Inserts with null appender_id',
    RAISED_407);
 END@

-- Test03: Inserts an appender with negative appender_id.
CREATE OR REPLACE PROCEDURE TEST_03()
 BEGIN
  DECLARE RAISED_LG0A1 BOOLEAN; -- For a controlled error.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0A1'
    SET RAISED_LG0A1 = TRUE;

  DELETE FROM LOGDATA.APPENDERS;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (-1, 'test3');

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test03: Inserts with negative appender_id',
    RAISED_LG0A1);
 END@

-- Test04: Updates an appender with null appender_id.
CREATE OR REPLACE PROCEDURE TEST_04()
 BEGIN
  DECLARE RAISED_407 BOOLEAN; -- Not null.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '23502'
    SET RAISED_407 = TRUE;

  DELETE FROM LOGDATA.APPENDERS;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (4, 'test4');
  UPDATE LOGDATA.APPENDERS
    SET APPENDER_ID = NULL
    WHERE APPENDER_ID = 4;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test04: Updates with null appender_id',
    RAISED_407);
 END@

-- Test05: Updates an appender with negative appender_id.
CREATE OR REPLACE PROCEDURE TEST_05()
 BEGIN
  DECLARE RAISED_LG0A1 BOOLEAN; -- For a controlled error.
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0A1'
    SET RAISED_LG0A1 = TRUE;

  DELETE FROM LOGDATA.APPENDERS;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (5, 'test5');
  UPDATE LOGDATA.APPENDERS
    SET APPENDER_ID = -1
    WHERE APPENDER_ID = 5;

  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test05: Updates with negative appender_id',
    RAISED_LG0A1);
 END@

-- Test06: Updates an appender normally.
CREATE OR REPLACE PROCEDURE TEST_06()
 BEGIN
  DELETE FROM LOGDATA.APPENDERS;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (6, 'test6');
  UPDATE LOGDATA.APPENDERS
    SET APPENDER_ID = 7
    WHERE APPENDER_ID = 6;
 END@

-- Test07: Deletes an appender normally.
CREATE OR REPLACE PROCEDURE TEST_07()
 BEGIN
  DELETE FROM LOGDATA.APPENDERS;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (7, 'test7');
  DELETE FROM LOGDATA.APPENDERS
    WHERE APPENDER_ID = 7;
 END@

-- Test08: Deletes all appenders.
CREATE OR REPLACE PROCEDURE TEST_08()
 BEGIN
  DELETE FROM LOGDATA.APPENDERS;
  INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
    (8, 'test8');
  DELETE FROM LOGDATA.APPENDERS;
 END@

-- Register the suite.
INSERT INTO DB2UNIT.SUITES (SUITE_NAME) VALUES
  (CURRENT SCHEMA) @

