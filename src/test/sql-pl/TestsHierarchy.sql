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
 * Version: 2014-04-21 1-Beta
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOGGER_1B @

SET PATH = "SYSIBM", "SYSFUN", "SYSPROC", "SYSIBMADM", LOGGER_1B @

--ALTER MODULE LOGGER DROP FUNCTION IS_LOGGER_ACTIVE2 @

BEGIN
DECLARE QUERY VARCHAR(4096);

-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsHierarchy: Preparing environment');

-- Extract the private function and pulish it.
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
  AND FUNCSCHEMA LIKE 'LOGGER_1B%';
EXECUTE IMMEDIATE QUERY;
END@

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

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

DECLARE RAISED_407 BOOLEAN DEFAULT FALSE; -- Null value.
DECLARE RAISED_420 BOOLEAN DEFAULT FALSE; -- Invalid string.
DECLARE EXPECTED_ACTIVE BOOLEAN;
DECLARE ACTUAL_ACTIVE BOOLEAN;
DECLARE HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY;
DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.LOGGER_ID;

DECLARE CONTINUE HANDLER FOR SQLSTATE '22018'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_420 = TRUE;
  END;

-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Test01: Tests normal hierarchy.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test01: Tests normal hierarchy');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '0';
SET LOGGER = 0;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test02: Tests null hierarchy.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test02: Tests null hierarchy');
SET EXPECTED_ACTIVE = FALSE;
SET HIERARCHY = NULL;
SET LOGGER = 0;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test03: Tests empty hierarchy.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test03: Tests empty hierarchy');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '';
SET LOGGER = 0;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (RAISED_420 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised 420');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 420');
END IF;
SET RAISED_420 = FALSE;

-- Test04: Tests invalid hierarchy.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test04: Tests invalid hierarchy');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '-andres-';
SET LOGGER = 0;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (RAISED_420 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised 420');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 420');
END IF;
SET RAISED_420 = FALSE;

-- Test05: Tests null logger.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test05: Tests null logger');
SET EXPECTED_ACTIVE = FALSE;
SET HIERARCHY = '0';
SET LOGGER = NULL;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test06: Tests negative logger.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test06: Tests negative logger');
SET EXPECTED_ACTIVE = FALSE;
SET HIERARCHY = '0';
SET LOGGER = -1;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test07: Tests two levels - root.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test07: Tests two levels - root');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '0,1';
SET LOGGER = 0;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test08: Tests three levels - root.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test08: Tests three levels - root');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '0,1,2';
SET LOGGER = 0;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test09: Tests two levels - root - no consecutive.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test09: Tests two levels - root - no consecutive');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '0,5';
SET LOGGER = 0;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test10: Tests three levels - root - no consecutive.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test10: Tests three levels - root - no consecutive');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '0,5,11';
SET LOGGER = 0;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test11: Tests two levels - first level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test11: Tests two levels - first level');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '0,1';
SET LOGGER = 1;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test12: Tests two levels - first level - no.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test12: Tests two levels - first level - no');
SET EXPECTED_ACTIVE = FALSE;
SET HIERARCHY = '0,1';
SET LOGGER = 2;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test13: Tests three levels - first level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test13: Tests three levels - first level');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '0,1,2';
SET LOGGER = 1;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test14: Tests three levels - first level - no.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test14: Tests three levels - first level - no');
SET EXPECTED_ACTIVE = FALSE;
SET HIERARCHY = '0,1,2';
SET LOGGER = 3;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test15: Tests three levels - second level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test15: Tests three levels - second level');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '0,1,2';
SET LOGGER = 2;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test16: Tests three levels - first level - no consecutive.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test16: Tests three levels - first level - no consecutive');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '0,3,7';
SET LOGGER = 3;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test17: Tests three levels - second level - no consecutive.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test17: Tests three levels - second level - no consecutive');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '0,3,7';
SET LOGGER = 7;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test18: Tests three levels - second level - no consecutive with root.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test18: Tests three levels - second level - no consecutive with root');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '0,12,13';
SET LOGGER = 13;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test19: Tests three levels - second level - consecutive with root.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test19: Tests three levels - second level - consecutive with root');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '0,1,13';
SET LOGGER = 13;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test20: Tests three levels - first level - consecutive with root.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test20: Tests three levels - first level - consecutive with root');
SET EXPECTED_ACTIVE = TRUE;
SET HIERARCHY = '0,1,13';
SET LOGGER = 1;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test21: Tests only root - other logger.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test21: Tests only root - other logger');
SET EXPECTED_ACTIVE = FALSE;
SET HIERARCHY = '0';
SET LOGGER = 1;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Test22: Tests only root - other logger.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test22: Tests only root - other logger');
SET EXPECTED_ACTIVE = FALSE;
SET HIERARCHY = '0';
SET LOGGER = 5;
SET ACTUAL_ACTIVE = LOGGER.IS_LOGGER_ACTIVE2(HIERARCHY, LOGGER);
IF (EXPECTED_ACTIVE <> ACTUAL_ACTIVE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, BOOL_TO_CHAR(EXPECTED_ACTIVE) || ' - ' || BOOL_TO_CHAR(ACTUAL_ACTIVE));
END IF;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsHierarchy: Cleaning environment');
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE)
  VALUES ('autonomousLogging', 'true'),
         ('defaultRootLevelId', '3'),
         ('internalCache', 'true'),
         ('logInternals', 'false'),
         ('secondsToRefresh', '30');
DELETE FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsHierarchy: Finished succesfully');
COMMIT;

END @

ALTER MODULE LOGGER
  DROP FUNCTION IS_LOGGER_ACTIVE2 @

DROP FUNCTION BOOL_TO_CHAR @

