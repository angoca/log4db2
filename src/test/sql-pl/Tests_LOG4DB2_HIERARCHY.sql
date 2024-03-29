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
 * Tests for the logger's hierarchy.
 *
 * Version: 2022-06-07 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOGGER_1RC @

-- Install
BEGIN
 DECLARE QUERY VARCHAR(4096);
 DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
 DECLARE CONTINUE HANDLER FOR SQLSTATE '42710' BEGIN END;

 SET QUERY = 'ALTER MODULE LOGGER DROP SPECIFIC FUNCTION F_IS_LOGGER_ACTIVE2';
 EXECUTE IMMEDIATE QUERY;

 -- Extract the private function and publish it.
 SELECT
  REPLACE
   (REPLACE
    (REPLACE
     (REPLACE
      (REPLACE
       (BODY,
       'ALTER MODULE LOGGER ADD',
       'ALTER MODULE LOGGER PUBLISH'),
      'FUNCTION IS_LOGGER_ACTIVE',
      'FUNCTION IS_LOGGER_ACTIVE2'),
     'SPECIFIC F_IS_LOGGER_ACTIVE',
     'SPECIFIC F_IS_LOGGER_ACTIVE2'),
    'F_IS_LOGGER_ACTIVE: BEGIN',
   'F_IS_LOGGER_ACTIVE2: BEGIN'),
  'END F_IS_LOGGER_ACTIVE',
 'END F_IS_LOGGER_ACTIVE2')
 INTO QUERY
 FROM SYSCAT.FUNCTIONS
 WHERE FUNCNAME LIKE 'IS_LOGGER_ACTIVE'
 AND FUNCSCHEMA LIKE 'LOGGER_1RC';

 EXECUTE IMMEDIATE QUERY;
END @

SET CURRENT SCHEMA LOG4DB2_HIERARCHY @

BEGIN
 DECLARE STATEMENT VARCHAR(128);
 DECLARE CONTINUE HANDLER FOR SQLSTATE '42710' BEGIN END;
 SET STATEMENT = 'CREATE SCHEMA LOG4DB2_HIERARCHY';
 EXECUTE IMMEDIATE STATEMENT;
END @

-- Helper function to convert boolean values into characters.
CREATE OR REPLACE FUNCTION BOOL_TO_CHAR(
  IN VALUE BOOLEAN
  ) RETURNS CHAR(5)
 BEGIN
  DECLARE RET CHAR(5) DEFAULT 'FALSE';
  IF (VALUE IS NULL) THEN
    SET RET = 'NULL';
  ELSEIF (VALUE = TRUE) THEN
   SET RET = 'TRUE';
  END IF;
  RETURN RET;
 END@

-- Test fixtures
CREATE OR REPLACE PROCEDURE ONE_TIME_SETUP()
 BEGIN
  CALL DB2UNIT.SET_AUTONOMOUS(FALSE);
 END @

CREATE OR REPLACE PROCEDURE SETUP()
 BEGIN
  CALL LOGADMIN.DELETE_LOGGERS();
 END @

CREATE OR REPLACE PROCEDURE TEAR_DOWN()
 BEGIN
  -- Empty
 END @

CREATE OR REPLACE PROCEDURE ONE_TIME_TEAR_DOWN()
 BEGIN
  CALL LOGGER_1RC.LOGADMIN.RESET_TABLES();
 END @

 -- Tests

-- Test01: Tests normal hierarchy.
CREATE OR REPLACE PROCEDURE TEST_01()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '0';
  SET LOGGER = 0;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test01: Tests normal hierarchy',
    EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test02: Tests null hierarchy.
CREATE OR REPLACE PROCEDURE TEST_02()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = FALSE;
  SET HIERARCHY = NULL;
  SET LOGGER = 0;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test02: Tests null hierarchy',
    EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test03: Tests empty hierarchy.
CREATE OR REPLACE PROCEDURE TEST_03()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  DECLARE RAISED_420 BOOLEAN DEFAULT FALSE; -- Invalid string.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '22018'
    SET RAISED_420 = TRUE;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '';
  SET LOGGER = 0;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
  
  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test03: Tests empty hierarchy',
    RAISED_420);
 END @

-- Test04: Tests invalid hierarchy.
CREATE OR REPLACE PROCEDURE TEST_04()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  DECLARE RAISED_420 BOOLEAN DEFAULT FALSE; -- Invalid string.
  DECLARE CONTINUE HANDLER FOR SQLSTATE '22018'
    SET RAISED_420 = TRUE;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '-andres-';
  SET LOGGER = 0;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
  
  CALL DB2UNIT.ASSERT_BOOLEAN_TRUE('Test04: Tests invalid hierarchy',
    RAISED_420);
 END @

-- Test05: Tests null logger.
CREATE OR REPLACE PROCEDURE TEST_05()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = FALSE;
  SET HIERARCHY = '0';
  SET LOGGER = NULL;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test05: Tests null logger',
    EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test06: Tests negative logger.
CREATE OR REPLACE PROCEDURE TEST_06()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = FALSE;
  SET HIERARCHY = '0';
  SET LOGGER = -1;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test06: Tests negative logger',
    EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test07: Tests two levels - root.
CREATE OR REPLACE PROCEDURE TEST_07()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '0,1';
  SET LOGGER = 0;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test07: Tests two levels - root',
    EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test08: Tests three levels - root.
CREATE OR REPLACE PROCEDURE TEST_08()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '0,1,2';
  SET LOGGER = 0;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test08: Tests three levels - root',
    EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test09: Tests two levels - root - no consecutive.
CREATE OR REPLACE PROCEDURE TEST_09()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '0,5';
  SET LOGGER = 0;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test09: Tests two levels - root - no '
    || 'consecutive', EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test10: Tests three levels - root - no consecutive.
CREATE OR REPLACE PROCEDURE TEST_10()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '0,5,11';
  SET LOGGER = 0;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test10: Tests three levels - root - no '
    || 'consecutive', EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test11: Tests two levels - first level.
CREATE OR REPLACE PROCEDURE TEST_11()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '0,1';
  SET LOGGER = 1;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test11: Tests two levels - first level',
    EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test12: Tests two levels - first level - no.
CREATE OR REPLACE PROCEDURE TEST_12()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = FALSE;
  SET HIERARCHY = '0,1';
  SET LOGGER = 2;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test12: Tests two levels - first level '
    || '- no', EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test13: Tests three levels - first level.
CREATE OR REPLACE PROCEDURE TEST_13()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '0,1,2';
  SET LOGGER = 1;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test13: Tests three levels - first '
    || 'level', EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test14: Tests three levels - first level - no.
CREATE OR REPLACE PROCEDURE TEST_14()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = FALSE;
  SET HIERARCHY = '0,1,2';
  SET LOGGER = 3;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test14: Tests three levels - first '
    || 'level - no', EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test15: Tests three levels - second level.
CREATE OR REPLACE PROCEDURE TEST_15()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '0,1,2';
  SET LOGGER = 2;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test15: Tests three levels - second '
    || 'level', EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test16: Tests three levels - first level - no consecutive.
CREATE OR REPLACE PROCEDURE TEST_16()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '0,3,7';
  SET LOGGER = 3;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test16: Tests three levels - first '
    || 'level - no consecutive',
    EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test17: Tests three levels - second level - no consecutive.
CREATE OR REPLACE PROCEDURE TEST_17()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '0,3,7';
  SET LOGGER = 7;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test17: Tests three levels - second '
    || 'level - no consecutive', EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test18: Tests three levels - second level - no consecutive with root.
CREATE OR REPLACE PROCEDURE TEST_18()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '0,12,13';
  SET LOGGER = 13;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test18: Tests three levels - second '
    || 'level - no consec root', EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test19: Tests three levels - second level - consecutive with root.
CREATE OR REPLACE PROCEDURE TEST_19()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '0,1,13';
  SET LOGGER = 13;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test19: Tests three levels - second '
    || 'level - consec root', EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test20: Tests three levels - first level - consecutive with root.
CREATE OR REPLACE PROCEDURE TEST_20()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = TRUE;
  SET HIERARCHY = '0,1,13';
  SET LOGGER = 1;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test20: Tests three levels - first '
    || 'level - consecutive with root', EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test21: Tests only root - other logger.
CREATE OR REPLACE PROCEDURE TEST_21()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = FALSE;
  SET HIERARCHY = '0';
  SET LOGGER = 1;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test21: Tests only root - other logger',
    EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test22: Tests only root - other logger.
CREATE OR REPLACE PROCEDURE TEST_22()
 BEGIN
  DECLARE EXPECTED_ACTIVE BOOLEAN;
  DECLARE ACTUAL_ACTIVE BOOLEAN;
  DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

  SET EXPECTED_ACTIVE = FALSE;
  SET HIERARCHY = '0';
  SET LOGGER = 5;
  SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);

  CALL DB2UNIT.ASSERT_BOOLEAN_EQUALS('Test22: Tests only root - other logger',
    EXPECTED_ACTIVE, ACTUAL_ACTIVE);
 END @

-- Test23: Size of the hierarchy column.
CREATE OR REPLACE PROCEDURE TEST_23()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE EXPECTED_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE ACTUAL_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;

  DECLARE INDEX INT;
  DECLARE LOG_ID ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;

  SET INDEX = 0;
  CALL LOGGER.GET_LOGGER(NULL, LOG_ID);
  WHILE (LOG_ID < 999) DO
   CALL LOGGER.GET_LOGGER(INDEX || '', LOG_ID);
   SET INDEX = INDEX + 1;
  END WHILE;

  SET LOGGER_NAME = 'a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.r.s.t.u.v.w.x.y.z.1.2.3'
    || '.4';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOG_ID);
  SET EXPECTED_HIERARCHY = '0,1000,1001,1002,1003,1004,1005,1006,1007,1008,'
    || '1009,1010,1011,1012,1013,1014,1015,1016,1017,1018,1019,1020,1021,1022,'
    || '1023,1024,1025,1026,1027,1028,1029';
  SET ACTUAL_HIERARCHY = (SELECT HIERARCHY
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE LOGGER_ID = 1029);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test23: Size of the hierarchy column',
    EXPECTED_HIERARCHY, ACTUAL_HIERARCHY);
 END @

-- Test24: Size of the hierarchy column.
CREATE OR REPLACE PROCEDURE TEST_24()
 BEGIN
  DECLARE LOGGER_NAME ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
  DECLARE EXPECTED_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
  DECLARE ACTUAL_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;

  DECLARE INDEX INT;
  DECLARE LOG_ID ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;

  SET INDEX = 0;
  CALL LOGGER.GET_LOGGER(NULL, LOG_ID);
  WHILE (LOG_ID < 999) DO
   CALL LOGGER.GET_LOGGER(INDEX || '', LOG_ID);
   SET INDEX = INDEX + 1;
  END WHILE;

  SET LOGGER_NAME = 'a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.r.s.t.u.v.w.x.y.z.1.2.3'
    || '.4.5';
  CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOG_ID);
  SET EXPECTED_HIERARCHY = NULL;
  SET ACTUAL_HIERARCHY = (SELECT HIERARCHY
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE LOGGER_ID = 1030);

  CALL DB2UNIT.ASSERT_STRING_EQUALS('Test24: Size of the hierarchy column',
    EXPECTED_HIERARCHY, ACTUAL_HIERARCHY);
 END @

-- Register the suite.
CALL DB2UNIT.REGISTER_SUITE(CURRENT SCHEMA) @

