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
 * Tests for the logger cache functionality.
 *
 * Version: 2022-06-07 v1
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOG4DB2_CACHE_CONFIGURATION @

BEGIN
 DECLARE STATEMENT VARCHAR(128);
 DECLARE CONTINUE HANDLER FOR SQLSTATE '42710' BEGIN END;
 SET STATEMENT = 'CREATE SCHEMA LOG4DB2_CACHE_CONFIGURATION';
 EXECUTE IMMEDIATE STATEMENT;
END @

-- Test fixtures
CREATE OR REPLACE PROCEDURE ONE_TIME_SETUP()
 P_ONE_TIME_SETUP: BEGIN
  DELETE FROM LOGDATA.CONFIGURATION;
 END P_ONE_TIME_SETUP @

CREATE OR REPLACE PROCEDURE SETUP()
 P_SETUP: BEGIN
  CALL LOGGER.DEACTIVATE_CACHE();
 END P_SETUP @

CREATE OR REPLACE PROCEDURE TEAR_DOWN()
 P_TEAR_DOWN: BEGIN
  DELETE FROM LOGDATA.CONFIGURATION;
 END P_TEAR_DOWN @

CREATE OR REPLACE PROCEDURE ONE_TIME_TEAR_DOWN()
 P_ONE_TIME_TEAR_DOWN: BEGIN
  CALL LOGGER_1.LOGADMIN.RESET_TABLES();
  CALL LOGGER.ACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
 END P_ONE_TIME_TEAR_DOWN @

-- Tests
-- A: Activate
-- I: Insert
-- R: Refresh
-- U: Update

-- Test01: Get value from cache - Active cache.
-- A-I---
CREATE OR REPLACE PROCEDURE TEST_01()
 BEGIN
  DECLARE MY_KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
  DECLARE EXPECTED_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE ACTUAL_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

  SET MY_KEY = 'Test01';
  SET EXPECTED_VALUE = 'Val01';
  CALL LOGGER.ACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, EXPECTED_VALUE);
  -- The cache will be refreshed and the right value will be returned.
  SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test01: Get value from cache - Active '
    || 'cache',
    EXPECTED_VALUE, ACTUAL_VALUE);
 END@

-- Test02: Get value from cache - Active cache + refresh.
-- A-IR--
CREATE OR REPLACE PROCEDURE TEST_02()
 BEGIN
  DECLARE MY_KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
  DECLARE EXPECTED_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE ACTUAL_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

  SET MY_KEY = 'Test02';
  SET EXPECTED_VALUE = 'Val02';
  CALL LOGGER.ACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, EXPECTED_VALUE);
  CALL LOGGER.REFRESH_CACHE();
  -- This will always return the value.
  SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test02: Get value from cache - Active '
    || 'cache + refresh',
    EXPECTED_VALUE, ACTUAL_VALUE);
 END@

-- Test03: Get new value from cache - Active cache.
-- A-I-U-
CREATE OR REPLACE PROCEDURE TEST_03()
 BEGIN
  DECLARE MY_KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
  DECLARE EXPECTED_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE ACTUAL_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

  SET MY_KEY = 'Test03';
  SET EXPECTED_VALUE = 'NewValue';
  CALL LOGGER.ACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'Val03');
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = EXPECTED_VALUE
    WHERE KEY = MY_KEY;
  -- This will return the most recent value.
  SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test03: Get new value from cache - Active '
    || 'cache',
    EXPECTED_VALUE, ACTUAL_VALUE);
 END@

-- Test04: Get new value from cache - Active cache + refresh.
-- A-I-UR
CREATE OR REPLACE PROCEDURE TEST_04()
 BEGIN
  DECLARE MY_KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
  DECLARE EXPECTED_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE ACTUAL_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

  SET MY_KEY = 'Test04';
  SET EXPECTED_VALUE = 'NewValue';
  CALL LOGGER.ACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'Val04');
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = EXPECTED_VALUE
    WHERE KEY = MY_KEY;
  CALL LOGGER.REFRESH_CACHE();
  -- This always will return the most recent value.
  SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test04: Get new value from cache - Active '
    || 'cache + refresh',
    EXPECTED_VALUE, ACTUAL_VALUE);
 END@

-- Test05: Get old value from cache - Active cache + refresh.
-- A-IRU-
CREATE OR REPLACE PROCEDURE TEST_05()
 BEGIN
  DECLARE MY_KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
  DECLARE EXPECTED_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE ACTUAL_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

  SET MY_KEY = 'Test05';
  SET EXPECTED_VALUE = 'Val05';
  CALL LOGGER.ACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, EXPECTED_VALUE);
  CALL LOGGER.REFRESH_CACHE();
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = 'NewValue'
    WHERE KEY = MY_KEY;
  -- This will return the previous value in the cache.
  SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test05: Get old value from cache - Active '
    || 'cache + refresh',
    EXPECTED_VALUE, ACTUAL_VALUE);
 END@

-- Test06: Get new value from cache - Active cache.
-- ARI---
CREATE OR REPLACE PROCEDURE TEST_06()
 BEGIN
  DECLARE MY_KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
  DECLARE EXPECTED_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE ACTUAL_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

  SET MY_KEY = 'Test06';
  SET EXPECTED_VALUE = NULL;
  CALL LOGGER.ACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
  INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'Val06');
  -- This will return null because the cache was just refreshed.
  SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test06: Get new value from cache - Active '
    || 'cache',
    EXPECTED_VALUE, ACTUAL_VALUE);
 END@

-- Test07: Get null from cache - Active cache.
CREATE OR REPLACE PROCEDURE TEST_07()
 BEGIN
  DECLARE MY_KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
  DECLARE EXPECTED_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE ACTUAL_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

  SET MY_KEY = 'Test07';
  SET EXPECTED_VALUE = NULL;
  CALL LOGGER.ACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
  SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test07: Get null from cache - Active '
    || 'cache',
    EXPECTED_VALUE, ACTUAL_VALUE);
 END@

-- Test08: Get new value - Deactive cache.
CREATE OR REPLACE PROCEDURE TEST_08()
 BEGIN
  DECLARE MY_KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
  DECLARE EXPECTED_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE ACTUAL_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

  SET MY_KEY = 'Test08';
  SET EXPECTED_VALUE = 'Val08';
  CALL LOGGER.DEACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'OldValue');
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = EXPECTED_VALUE
    WHERE KEY = MY_KEY;
  SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test08: Get new vale - Deactive cache',
    EXPECTED_VALUE, ACTUAL_VALUE);
 END@

-- Test09: Get new value, refresh - Deactive cache.
CREATE OR REPLACE PROCEDURE TEST_09()
 BEGIN
  DECLARE MY_KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
  DECLARE EXPECTED_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE ACTUAL_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

  SET MY_KEY = 'Test09';
  SET EXPECTED_VALUE = 'Val09';
  CALL LOGGER.DEACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'OldValue');
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = EXPECTED_VALUE
    WHERE KEY = MY_KEY;
  CALL LOGGER.REFRESH_CACHE();
  SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test09: Get new vale, refresh - Deactive '
   || 'cache',
    EXPECTED_VALUE, ACTUAL_VALUE);
 END@

-- Test10: Get null - Deactive cache.
CREATE OR REPLACE PROCEDURE TEST_10()
 BEGIN
  DECLARE MY_KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
  DECLARE EXPECTED_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE ACTUAL_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

  SET MY_KEY = 'Test10';
  SET EXPECTED_VALUE = NULL;
  CALL LOGGER.DEACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'OldValue');
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = EXPECTED_VALUE
    WHERE KEY = MY_KEY;
  SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test10: Get null - Deactive cache',
    EXPECTED_VALUE, ACTUAL_VALUE);
 END@

-- Test11: Get null, refresh - Deactive cache.
CREATE OR REPLACE PROCEDURE TEST_11()
 BEGIN
  DECLARE MY_KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
  DECLARE EXPECTED_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE ACTUAL_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

  SET MY_KEY = 'Test11';
  SET EXPECTED_VALUE = NULL;
  CALL LOGGER.DEACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'OldValue');
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = EXPECTED_VALUE
    WHERE KEY = MY_KEY;
  CALL LOGGER.REFRESH_CACHE();
  SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test11: Get null, refresh - Deactive '
    || 'cache',
    EXPECTED_VALUE, ACTUAL_VALUE);
 END@

-- Test12: Get null, refresh - Deactive cache.
CREATE OR REPLACE PROCEDURE TEST_12()
 BEGIN
  DECLARE MY_KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
  DECLARE EXPECTED_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE ACTUAL_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

  SET MY_KEY = 'Test11';
  SET EXPECTED_VALUE = NULL;
  CALL LOGGER.DEACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'OldValue');
  CALL LOGGER.REFRESH_CACHE();
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = EXPECTED_VALUE
    WHERE KEY = MY_KEY;
  SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test12: Get null, refresh - Deactive '
    || 'cache',
    EXPECTED_VALUE, ACTUAL_VALUE);
 END@

-- Register the suite.
CALL DB2UNIT.REGISTER_SUITE(CURRENT SCHEMA) @

