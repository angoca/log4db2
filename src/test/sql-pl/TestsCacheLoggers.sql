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
 * Tests for the logger cache functionality for logger.
 *
 * Version: 2014-04-21 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOG4DB2_CACHE_LOGGERS @

SET PATH = LOG4DB2_CACHE_LOGGERS @

CREATE SCHEMA LOG4DB2_CACHE_LOGGERS @

BEGIN
 DECLARE QUERY VARCHAR(4096);

 -- Drop previous function (if exist)
 SET QUERY = 'ALTER MODULE LOGGER_1RC.LOGGER DROP FUNCTION GET_LOGGER_DATA2';
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLSTATE '42704'
   BEGIN END;
  EXECUTE IMMEDIATE QUERY;
 END;

 SET QUERY = 'ALTER MODULE LOGGER_1RC.LOGGER DROP TYPE LOGGERS_ROW';
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLSTATE '42611'
   BEGIN END;
  EXECUTE IMMEDIATE QUERY;
 END;
 SET QUERY = 'ALTER MODULE LOGGER_1RC.LOGGER PUBLISH '
   || 'TYPE LOGGERS_ROW AS ROW ('
   || 'NAME ANCHOR COMPLETE_LOGGER_NAME, '
   || 'LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID, '
   || 'HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY)';
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLSTATE '42611'
   BEGIN END;
  EXECUTE IMMEDIATE QUERY;
 END;

 -- Extract the private function and publish it.
 SELECT
   REPLACE
    (REPLACE
     (REPLACE
      (REPLACE
       (REPLACE
        (BODY,
        'ALTER MODULE LOGGER ADD',
        'ALTER MODULE LOGGER_1RC.LOGGER PUBLISH'),
       'FUNCTION GET_LOGGER_DATA',
       'FUNCTION GET_LOGGER_DATA2'),
      'SPECIFIC F_GET_LOGGER_DATA',
      'SPECIFIC F_GET_LOGGER_DATA2'),
     'F_GET_LOGGER_DATA: BEGIN',
     'F_GET_LOGGER_DATA2: BEGIN'),
    'END F_GET_LOGGER_DATA',
    'END F_GET_LOGGER_DATA2')
   INTO QUERY
   FROM SYSCAT.FUNCTIONS
   WHERE FUNCNAME LIKE 'GET_LOGGER_DATA'
   AND FUNCSCHEMA LIKE 'LOGGER_1RC';
 BEGIN
  EXECUTE IMMEDIATE QUERY;
 END;
 COMMIT;
END @

CREATE OR REPLACE PROCEDURE UNINSTALL ()
 BEGIN
  DECLARE QUERY VARCHAR(4096);
  SET QUERY = 'ALTER MODULE LOGGER DROP FUNCTION GET_LOGGER_DATA2';
  EXECUTE IMMEDIATE QUERY;
  SET QUERY = 'ALTER MODULE LOGGER DROP TYPE LOGGERS_ROW';
  EXECUTE IMMEDIATE QUERY;
  SET QUERY = 'ALTER MODULE LOGGER ADD '
    || 'TYPE LOGGERS_ROW AS ROW ('
    || 'NAME ANCHOR COMPLETE_LOGGER_NAME, '
    || 'LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID, '
    || 'HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY)';
  EXECUTE IMMEDIATE QUERY;
 END @
-- Test fixtures
CREATE OR REPLACE PROCEDURE ONE_TIME_SETUP()
 P_ONE_TIME_SETUP: BEGIN
  CALL LOGGER.DEACTIVATE_CACHE();
  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID <> 0;
 END P_ONE_TIME_SETUP @


CREATE OR REPLACE PROCEDURE SETUP()
 P_SETUP: BEGIN
  UPDATE LOGDATA.CONFIGURATION
    SET VALUE = '4'
    WHERE KEY = 'defaultRootLevelId';
 END P_SETUP @

CREATE OR REPLACE PROCEDURE TEAR_DOWN()
 P_TEAR_DOWN: BEGIN
  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID <> 0;
  CALL LOGGER.ACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
 END P_TEAR_DOWN @

CREATE OR REPLACE PROCEDURE ONE_TIME_TEAR_DOWN()
 P_ONE_TIME_TEAR_DOWN: BEGIN

  DELETE FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID <> 0;
  DELETE FROM LOGDATA.CONFIGURATION;
  INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE)
    VALUES ('autonomousLogging', 'false'),
           ('defaultRootLevelId', '3'),
           ('internalCache', 'true'),
           ('logInternals', 'false'),
           ('secondsToRefresh', '30');
  CALL LOGGER.ACTIVATE_CACHE();
 END P_ONE_TIME_TEAR_DOWN @

-- Tests

-- Test01: Test GetLoggerName with cache old.
CREATE OR REPLACE PROCEDURE TEST_01()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;

  SET LOG_ID = 1;
  SET EXPECTED_NAME = 'LEV01';
  CALL LOGGER.ACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
  INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
    VALUES (LOG_ID, EXPECTED_NAME, 0, NULL);
  SET ACTUAL_NAME = LOGGER.GET_LOGGER_NAME(LOG_ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test01: Test GetLoggerName with cache old',
    EXPECTED_NAME, ACTUAL_NAME);
 END@

-- Test02: Test GetLoggerName with cache.
CREATE OR REPLACE PROCEDURE TEST_02()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;

  SET LOG_ID = 2;
  SET EXPECTED_NAME = 'LEV02';
  CALL LOGGER.ACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
    VALUES (LOG_ID, EXPECTED_NAME, 0, NULL);
  CALL LOGGER.REFRESH_CACHE();
  SET ACTUAL_NAME = LOGGER.GET_LOGGER_NAME(LOG_ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test02: Test GetLoggerName with cache',
    EXPECTED_NAME, ACTUAL_NAME);
 END@

-- Test03: Test GetLoggerName without cache.
CREATE OR REPLACE PROCEDURE TEST_03()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;

  SET LOG_ID = 3;
  SET EXPECTED_NAME = 'LEV03';
  CALL LOGGER.DEACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
    VALUES (LOG_ID, EXPECTED_NAME, 0, NULL);
  CALL LOGGER.REFRESH_CACHE();
  SET ACTUAL_NAME = LOGGER.GET_LOGGER_NAME(LOG_ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test03: Test GetLoggerName without cache',
    EXPECTED_NAME, ACTUAL_NAME);
 END@

-- Test04: Test GetLoggerData with cache old.
CREATE OR REPLACE PROCEDURE TEST_04()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE EXPECTED_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE EXPECTED_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE RET LOGGER.LOGGERS_ROW;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE ACTUAL_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;

  SET LOG_ID = 4;
  SET EXPECTED_NAME = 'LEV04';
  SET EXPECTED_LEVEL_ID = 1;
  SET EXPECTED_HIERARCHY = '0,' || LOG_ID;
  CALL LOGGER.ACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
  INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
    VALUES (LOG_ID, EXPECTED_NAME, 0, EXPECTED_LEVEL_ID);
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, LEVEL_ID, HIERARCHY)
    VALUES (LOG_ID, EXPECTED_LEVEL_ID, EXPECTED_HIERARCHY);
  SET RET = LOGGER.GET_LOGGER_DATA2(LOG_ID);
  SET ACTUAL_LEVEL_ID = RET.LEVEL_ID;
  SET ACTUAL_HIERARCHY = RET.HIERARCHY;
  SET ACTUAL_NAME = RET.NAME;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test04: Test GetLoggerData with cache old',
    EXPECTED_NAME, ACTUAL_NAME);
  CALL DB2UNIT.ASSERT_INT_EQUALS('Test04: Test GetLoggerData with cache old',
    EXPECTED_LEVEL_ID, ACTUAL_LEVEL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test04: Test GetLoggerData with cache old',
    EXPECTED_HIERARCHY, ACTUAL_HIERARCHY);
 END@

-- Test05: Test GetLoggerData with cache.
CREATE OR REPLACE PROCEDURE TEST_05()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE EXPECTED_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE EXPECTED_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE RET LOGGER.LOGGERS_ROW;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE ACTUAL_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;

  SET LOG_ID = 5;
  SET EXPECTED_NAME = 'LEV05';
  SET EXPECTED_HIERARCHY = '0,' || LOG_ID;
  SET EXPECTED_LEVEL_ID = 2;
  CALL LOGGER.ACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
    VALUES (LOG_ID, EXPECTED_NAME, 0, EXPECTED_LEVEL_ID);
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, LEVEL_ID, HIERARCHY)
    VALUES (LOG_ID, EXPECTED_LEVEL_ID, EXPECTED_HIERARCHY);
  CALL LOGGER.REFRESH_CACHE();
  SET RET = LOGGER.GET_LOGGER_DATA2(LOG_ID);
  SET ACTUAL_LEVEL_ID = RET.LEVEL_ID;
  SET ACTUAL_HIERARCHY = RET.HIERARCHY;
  SET ACTUAL_NAME = RET.NAME;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test05: Test GetLoggerData with cache',
    EXPECTED_NAME, ACTUAL_NAME);
  CALL DB2UNIT.ASSERT_INT_EQUALS('Test05: Test GetLoggerData with cache',
    EXPECTED_LEVEL_ID, ACTUAL_LEVEL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test05: Test GetLoggerData with cache',
    EXPECTED_HIERARCHY, ACTUAL_HIERARCHY);
 END@

-- Test06: Test GetLoggerData without cache.
CREATE OR REPLACE PROCEDURE TEST_06()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE EXPECTED_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE EXPECTED_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE RET LOGGER.LOGGERS_ROW;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE ACTUAL_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;

  SET LOG_ID = 6;
  SET EXPECTED_NAME = 'LEV06';
  SET EXPECTED_HIERARCHY = '0,' || LOG_ID;
  SET EXPECTED_LEVEL_ID = 4;
  CALL LOGGER.DEACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
    VALUES (LOG_ID, EXPECTED_NAME, 0, EXPECTED_LEVEL_ID);
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, LEVEL_ID, HIERARCHY)
    VALUES (LOG_ID, EXPECTED_LEVEL_ID, EXPECTED_HIERARCHY);
  CALL LOGGER.REFRESH_CACHE();
  SET RET = LOGGER.GET_LOGGER_DATA2(LOG_ID);
  SET ACTUAL_LEVEL_ID = RET.LEVEL_ID;
  SET ACTUAL_HIERARCHY = RET.HIERARCHY;
  SET ACTUAL_NAME = RET.NAME;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test06: Test GetLoggerData without cache',
    EXPECTED_NAME, ACTUAL_NAME);
  CALL DB2UNIT.ASSERT_INT_EQUALS('Test06: Test GetLoggerData without cache',
    EXPECTED_LEVEL_ID, ACTUAL_LEVEL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test06: Test GetLoggerData without cache',
    EXPECTED_HIERARCHY, ACTUAL_HIERARCHY);
 END@

-- Test07: Test GetLoggerName inexistant with cache.
CREATE OR REPLACE PROCEDURE TEST_07()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;

  SET LOG_ID = 7;
  SET EXPECTED_NAME = 'Unknown';
  CALL LOGGER.ACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
  SET ACTUAL_NAME = LOGGER.GET_LOGGER_NAME(LOG_ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test07: GetLoggerName inexistant cache',
    EXPECTED_NAME, ACTUAL_NAME);
 END@

-- Test08: Test GetLoggerData inexistant with cache.
CREATE OR REPLACE PROCEDURE TEST_08()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE EXPECTED_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE EXPECTED_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE RET LOGGER.LOGGERS_ROW;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE ACTUAL_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;

  SET LOG_ID = 8;
  SET EXPECTED_NAME = 'Unknown';
  SET EXPECTED_LEVEL_ID = NULL;
  SET EXPECTED_HIERARCHY = NULL;
  CALL LOGGER.ACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
  SET RET = LOGGER.GET_LOGGER_DATA2(LOG_ID);
  SET ACTUAL_LEVEL_ID = RET.LEVEL_ID;
  SET ACTUAL_HIERARCHY = RET.HIERARCHY;
  SET ACTUAL_NAME = RET.NAME;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test08: GetLoggerData inexistant cache',
    EXPECTED_NAME, ACTUAL_NAME);
  CALL DB2UNIT.ASSERT_INT_EQUALS('Test08: GetLoggerData inexistant cache',
    EXPECTED_LEVEL_ID, ACTUAL_LEVEL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test08: GetLoggerData inexistant cache',
    EXPECTED_HIERARCHY, ACTUAL_HIERARCHY);
 END@

-- Test09: Test GetLoggerName ROOT with cache.
CREATE OR REPLACE PROCEDURE TEST_09()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;

 SET LOG_ID = 0;
  SET EXPECTED_NAME = 'ROOT';
  CALL LOGGER.ACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
  SET ACTUAL_NAME = LOGGER.GET_LOGGER_NAME(LOG_ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test09: GetLoggerName ROOT with cache',
    EXPECTED_NAME, ACTUAL_NAME);
 END@

-- Test10: Test GetLoggerName ROOT without cache.
CREATE OR REPLACE PROCEDURE TEST_10()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;

  SET LOG_ID = 0;
  SET EXPECTED_NAME = 'ROOT';
  CALL LOGGER.DEACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
  SET ACTUAL_NAME = LOGGER.GET_LOGGER_NAME(LOG_ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test1O: GetLoggerName ROOT without cache',
    EXPECTED_NAME, ACTUAL_NAME);
 END@

-- Test11: Test GetLoggerData ROOT with cache.
CREATE OR REPLACE PROCEDURE TEST_11()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE EXPECTED_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE EXPECTED_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE RET LOGGER.LOGGERS_ROW;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE ACTUAL_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;

  SET LOG_ID = 0;
  SET EXPECTED_NAME = 'ROOT';
  SET EXPECTED_HIERARCHY = LOG_ID;
  SET EXPECTED_LEVEL_ID = 3;
  CALL LOGGER.ACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
  SET RET = LOGGER.GET_LOGGER_DATA2(LOG_ID);
  SET ACTUAL_LEVEL_ID = RET.LEVEL_ID;
  SET ACTUAL_HIERARCHY = RET.HIERARCHY;
  SET ACTUAL_NAME = RET.NAME;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test11: 1GetLoggerData ROOT with cache',
    EXPECTED_NAME, ACTUAL_NAME);
  CALL DB2UNIT.ASSERT_INT_EQUALS('Test11: 2GetLoggerData ROOT with cache',
    EXPECTED_LEVEL_ID, ACTUAL_LEVEL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test11: 3GetLoggerData ROOT with cache',
    EXPECTED_HIERARCHY, ACTUAL_HIERARCHY);
 END@

-- Test12: Test GetLoggerData ROOT without cache.
CREATE OR REPLACE PROCEDURE TEST_12()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE EXPECTED_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE EXPECTED_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE RET LOGGER.LOGGERS_ROW;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE ACTUAL_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;

  SET LOG_ID = 0;
  SET EXPECTED_NAME = 'ROOT';
  SET EXPECTED_HIERARCHY = LOG_ID;
  SET EXPECTED_LEVEL_ID = 3;
  CALL LOGGER.DEACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
  SET RET = LOGGER.GET_LOGGER_DATA2(LOG_ID);
  SET ACTUAL_LEVEL_ID = RET.LEVEL_ID;
  SET ACTUAL_HIERARCHY = RET.HIERARCHY;
  SET ACTUAL_NAME = RET.NAME;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test12: 1GetLoggerData ROOT without cache',
    EXPECTED_NAME, ACTUAL_NAME);
  CALL DB2UNIT.ASSERT_INT_EQUALS('Test12: 2GetLoggerData ROOT without cache',
    EXPECTED_LEVEL_ID, ACTUAL_LEVEL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test12: 3GetLoggerData ROOT without cache',
    EXPECTED_HIERARCHY, ACTUAL_HIERARCHY);
 END@

-- Test13: Test GetLoggerName INTERNAL without cache.
CREATE OR REPLACE PROCEDURE TEST_13()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;

  SET LOG_ID = -1;
  SET EXPECTED_NAME = '-internal-';
  CALL LOGGER.DEACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
  SET ACTUAL_NAME = LOGGER.GET_LOGGER_NAME(LOG_ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test13: GetLoggerName INTERNAL no cache',
    EXPECTED_NAME, ACTUAL_NAME);
 END@

-- Test14: Test GetLoggerName null.
CREATE OR REPLACE PROCEDURE TEST_14()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;

  SET LOG_ID = NULL;
  SET EXPECTED_NAME = '-internal-';
  CALL LOGGER.ACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
  SET ACTUAL_NAME = LOGGER.GET_LOGGER_NAME(LOG_ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test14: Test GetLoggerName null',
    EXPECTED_NAME, ACTUAL_NAME);
 END@

-- Test15: Test GetLoggerData NULL without cache.
CREATE OR REPLACE PROCEDURE TEST_15()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE EXPECTED_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE EXPECTED_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE RET LOGGER.LOGGERS_ROW;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE ACTUAL_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;

 SET LOG_ID = NULL;
  SET EXPECTED_NAME = '-internal-';
  SET EXPECTED_HIERARCHY = LOG_ID;
  SET EXPECTED_LEVEL_ID = -1;
  CALL LOGGER.ACTIVATE_CACHE();
  CALL LOGGER.REFRESH_CACHE();
  SET RET = LOGGER.GET_LOGGER_DATA2(LOG_ID);
  SET ACTUAL_LEVEL_ID = RET.LEVEL_ID;
  SET ACTUAL_HIERARCHY = RET.HIERARCHY;
  SET ACTUAL_NAME = RET.NAME;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test15: 1GetLoggerData NULL without cache',
    EXPECTED_NAME, ACTUAL_NAME);
  CALL DB2UNIT.ASSERT_INT_EQUALS('Test15: 2GetLoggerData NULL without cache',
    EXPECTED_LEVEL_ID, ACTUAL_LEVEL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test15: 3GetLoggerData NULL without cache',
    EXPECTED_HIERARCHY, ACTUAL_HIERARCHY);
 END@

-- Test16: Test GetLoggerName two levels with cache.
CREATE OR REPLACE PROCEDURE TEST_16()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;

  SET LOG_ID = 17;
  SET EXPECTED_NAME = 'LEV16A.LEV16B';
  CALL LOGGER.ACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
    VALUES (16, 'LEV16A', 0, NULL);
  INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
    VALUES (LOG_ID, 'LEV16B', 16, NULL);
  CALL LOGGER.REFRESH_CACHE();
  SET ACTUAL_NAME = LOGGER.GET_LOGGER_NAME(LOG_ID);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test16: GetLoggerName two levels cache',
    EXPECTED_NAME, ACTUAL_NAME);
 END@

-- Test17: Test GetLoggerData two levels with cache.
CREATE OR REPLACE PROCEDURE TEST_17()
 BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXPECTED_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE EXPECTED_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE EXPECTED_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE RET LOGGER.LOGGERS_ROW;
  DECLARE ACTUAL_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
  DECLARE ACTUAL_LEVEL_ID ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LEVEL_ID;
  DECLARE ACTUAL_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;

  SET LOG_ID = 18;
  SET EXPECTED_NAME = 'LEV17A.LEV17B';
  SET EXPECTED_HIERARCHY = '0,17,' || LOG_ID;
  SET EXPECTED_LEVEL_ID = 2;
  CALL LOGGER.ACTIVATE_CACHE();
  INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
    VALUES (17, 'LEV17A', 0, NULL);
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, LEVEL_ID, HIERARCHY)
    VALUES (17, 3, '0,17,');
  INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
    VALUES (LOG_ID, 'LEV17B', 17, EXPECTED_LEVEL_ID);
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, LEVEL_ID, HIERARCHY)
    VALUES (LOG_ID, EXPECTED_LEVEL_ID, EXPECTED_HIERARCHY);
  CALL LOGGER.REFRESH_CACHE();
  SET RET = LOGGER.GET_LOGGER_DATA2(LOG_ID);
  SET ACTUAL_LEVEL_ID = RET.LEVEL_ID;
  SET ACTUAL_HIERARCHY = RET.HIERARCHY;
  SET ACTUAL_NAME = RET.NAME;

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test17: GetLoggerData two levels cache',
    EXPECTED_NAME, ACTUAL_NAME);
  CALL DB2UNIT.ASSERT_INT_EQUALS('Test17: GetLoggerData two levels cache',
    EXPECTED_LEVEL_ID, ACTUAL_LEVEL_ID);
  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test17: GetLoggerData two levels cache',
    EXPECTED_HIERARCHY, ACTUAL_HIERARCHY);
 END@

-- Register the suite.
INSERT INTO DB2UNIT.SUITES (SUITE_NAME) VALUES
  (CURRENT SCHEMA) @

