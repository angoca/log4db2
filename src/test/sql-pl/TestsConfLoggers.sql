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
 * Tests for the logger insertions (conf_loggers table).
 */

SET CURRENT SCHEMA LOGGER_1B @

SET PATH = "SYSIBM","SYSFUN","SYSPROC","SYSIBMADM", LOGGER_1B @

CREATE OR REPLACE FUNCTION GET_MAX_ID()
  RETURNS ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
 BEGIN
  DECLARE RET ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  SET RET = (SELECT MAX(LOGGER_ID)
    FROM LOGDATA.CONF_LOGGERS);
  RETURN RET;
 END@

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '0000';

DECLARE RAISED_LG0C1 BOOLEAN DEFAULT FALSE; -- For a controlled error.
DECLARE RAISED_LG0C2 BOOLEAN DEFAULT FALSE; -- For a controlled error.
DECLARE RAISED_LG0C3 BOOLEAN DEFAULT FALSE; -- For a controlled error.
DECLARE RAISED_LG0C4 BOOLEAN DEFAULT FALSE; -- For a controlled error.
DECLARE RAISED_LG0C5 BOOLEAN DEFAULT FALSE; -- For a controlled error.
DECLARE RAISED_LG0C6 BOOLEAN DEFAULT FALSE; -- For a controlled error.
DECLARE RAISED_407 BOOLEAN DEFAULT FALSE; -- Null value.
DECLARE RAISED_530 BOOLEAN DEFAULT FALSE; -- Foreign key.
DECLARE ACTUAL_LOGGER ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE ACTUAL_PARENT ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE ACTUAL_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
DECLARE EXPECTED_LOGGER ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE EXPECTED_PARENT ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE EXPECTED_LEVEL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
DECLARE TEMP ANCHOR TO LOGDATA.CONF_LOGGERS.LOGGER_ID;

-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0C1'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0C1 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0C2'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0C2 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0C3'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0C3 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0C4'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0C4 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0C5'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0C5 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0C6'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0C6 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE '23502'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_407 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE '23503'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_530 = TRUE;
  END;

-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'TestsConfLogger: Preparing environment');
SET RAISED_LG0C1 = FALSE;
SET RAISED_LG0C2 = FALSE;
SET RAISED_LG0C3 = FALSE;
SET RAISED_LG0C4 = FALSE;
SET RAISED_LG0C5 = FALSE;
SET RAISED_LG0C6 = FALSE;
SET RAISED_407 = FALSE;
SET RAISED_530 = FALSE;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = '3'
  WHERE KEY = 'defaultRootLevelId';
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = 'false'
  WHERE KEY = 'internalCache';
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = 'true'
  WHERE KEY = 'logInternals';
SET TEMP = GET_MAX_ID();
COMMIT;

-- Test01: Inserts a normal logger with id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test01: Inserts a normal logger with id');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T1', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 3; -- Default level
SET ACTUAL_LOGGER = EXPECTED_LOGGER;
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 3;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (ACTUAL_LOGGER, 'Test1', ACTUAL_PARENT, ACTUAL_LEVEL);
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID = GET_MAX_ID();
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_LOGGER = -2;
SET ACTUAL_LOGGER = -1;
SET EXPECTED_PARENT = -2;
SET ACTUAL_PARENT = -1;
SET EXPECTED_LEVEL = -2;
SET ACTUAL_LEVEL = -1;
COMMIT;

-- Test02: Inserts a normal logger without id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test02: Inserts a normal logger without id');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T2', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 3; -- Default level
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 3;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test2', ACTUAL_PARENT, ACTUAL_LEVEL);
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID = GET_MAX_ID();
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_LOGGER = -2;
SET ACTUAL_LOGGER = -1;
SET EXPECTED_PARENT = -2;
SET ACTUAL_PARENT = -1;
SET EXPECTED_LEVEL = -2;
SET ACTUAL_LEVEL = -1;
COMMIT;

-- Test03: Tests null id
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test03: Tests null id');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T3', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 4;
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 4;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (NULL, 'test3', ACTUAL_PARENT, ACTUAL_LEVEL);
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised 407');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 407');
END IF;
SET RAISED_407 = FALSE;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
COMMIT;

-- Test04: Tests negative id
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test04: Tests negative id');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T4', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 5;
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 5;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (-1, 'test4', ACTUAL_PARENT, ACTUAL_LEVEL);
IF (RAISED_LG0C3 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0C3');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0C3');
END IF;
SET RAISED_LG0C3 = FALSE;
COMMIT;

-- Test05: Tests null name
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test05: Tests null name');
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES (NULL, 0, 0);
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised 407');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 407');
END IF;
SET RAISED_407 = FALSE;
COMMIT;

-- Test06: Tests that the parent cannot be null
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test06: Tests that the parent cannot be null');
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('test6', NULL, 0);
IF (RAISED_LG0C2 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised LG0C2');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0C2');
END IF;
SET RAISED_LG0C2 = FALSE;
COMMIT;

-- Test07: Tests negative parent.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test07: Tests negative parent');
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('test7', -5, 0);
IF (RAISED_530 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised 530');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 530');
END IF;
SET RAISED_530 = FALSE;
COMMIT;

-- Test08: Tests null level
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test08: Tests null level');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T8', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = NULL;
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = NULL;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('test8', ACTUAL_PARENT, ACTUAL_LEVEL);
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID = GET_MAX_ID();
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_LOGGER = -2;
SET ACTUAL_LOGGER = -1;
SET EXPECTED_PARENT = -2;
SET ACTUAL_PARENT = -1;
SET EXPECTED_LEVEL = -2;
SET ACTUAL_LEVEL = -1;
COMMIT;

-- Test09: Tests negative level
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test09: Tests negative level');
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('test9', 0, -5);
IF (RAISED_530 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised 530');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 530');
END IF;
SET RAISED_530 = FALSE;
COMMIT;

-- Test10: Tests all null
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test10: Tests all null');
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES (NULL, NULL, NULL);
IF (RAISED_LG0C2 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0C2');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0C2');
END IF;
SET RAISED_LG0C2 = FALSE;
COMMIT;

-- Test11: Tests all null
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test11: Tests all null');
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (NULL, NULL, NULL, NULL);
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised 407');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 407');
END IF;
SET RAISED_407 = FALSE;
COMMIT;

-- Test12: Tests almost all null
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test12: Tests lmost all null');
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (NULL, 'test12', NULL, NULL);
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised 407');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 407');
END IF;
SET RAISED_407 = FALSE;
COMMIT;

-- Test13: Tests almost all null
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test13: Tests almost all null');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T13', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = NULL;
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = NULL;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (NULL, 'test13', ACTUAL_PARENT, ACTUAL_LEVEL);
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised 407');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 407');
END IF;
SET RAISED_407 = FALSE;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
COMMIT;

-- Test14: Tests that the given parent should exist 
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test14: Tests that the given parent should exist');
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('test14', 50, NULL);
IF (RAISED_530 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised 530');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 530');
END IF;
SET RAISED_530 = FALSE;
COMMIT;

-- Test15: Tests to insert root logger without parent.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test15: Tests to insert root logger without parent');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_LOGGER = 0;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = NULL;
SET ACTUAL_LOGGER = EXPECTED_LOGGER;
SET ACTUAL_PARENT = NULL;
SET ACTUAL_LEVEL = NULL;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (ACTUAL_LOGGER, 'ROOT', ACTUAL_PARENT, ACTUAL_LEVEL);
IF (RAISED_LG0C1 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0C1');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0C1');
END IF;
SET RAISED_LG0C1 = FALSE;
COMMIT;

-- Test16: Tests logger with id and null parent
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test16: Tests logger with id and null parent');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (5, 'test16', NULL, 0);
IF (RAISED_LG0C2 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0C2');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0C2');
END IF;
SET RAISED_LG0C2 = FALSE;
COMMIT;

-- Test17: Tests to update the logger_id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test17: Tests to update the logger_id');
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test17', 0, NULL);
UPDATE LOGDATA.CONF_LOGGERS
  SET LOGGER_ID = 1
  WHERE NAME = 'Test17';
IF (RAISED_LG0C4 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0C4');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0C4');
END IF;
SET RAISED_LG0C4 = FALSE;
COMMIT;

-- Test18: Tests to update the name.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test18: Tests to update the name');
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test18', 0, NULL);
SET EXPECTED_LOGGER = GET_MAX_ID();
UPDATE LOGDATA.CONF_LOGGERS
  SET NAME = 'Test18a'
  WHERE LOGGER_ID = EXPECTED_LOGGER; 
IF (RAISED_LG0C4 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0C4');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0C4');
END IF;
SET RAISED_LG0C4 = FALSE;
COMMIT;

-- Test19: Tests to update the parent.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test19: Tests to update the parent');
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test19', 0, NULL);
SET EXPECTED_LOGGER = GET_MAX_ID();
UPDATE LOGDATA.CONF_LOGGERS
  SET PARENT_ID = 0
  WHERE LOGGER_ID = EXPECTED_LOGGER;
IF (RAISED_LG0C4 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0C4');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0C4');
END IF;
SET RAISED_LG0C4 = FALSE;
COMMIT;

-- Test20: Tests to update the root's parent.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test20: Tests to update the root''s parent');
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test20', 0, NULL);
SET EXPECTED_LOGGER = GET_MAX_ID();
UPDATE LOGDATA.CONF_LOGGERS
  SET PARENT_ID = EXPECTED_LOGGER
  WHERE LOGGER_ID = 0;
IF (RAISED_LG0C4 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0C4');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0C4');
END IF;
SET RAISED_LG0C4 = FALSE;
COMMIT;

-- Test21: Tests to update the level from null.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test21: Tests to update the level from null');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T21', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 2;
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = NULL;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test21', ACTUAL_PARENT, ACTUAL_LEVEL);
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = EXPECTED_LEVEL
  WHERE LOGGER_ID = EXPECTED_LOGGER;
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE NAME = 'Test21';
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SET EXPECTED_LOGGER = -2;
SET ACTUAL_LOGGER = -1;
SET EXPECTED_PARENT = -2;
SET ACTUAL_PARENT = -1;
SET EXPECTED_LEVEL = -2;
SET ACTUAL_LEVEL = -1;
COMMIT;

-- Test22: Tests to update the level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test22: Tests to update the level');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T22', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 5;
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 3;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test22', ACTUAL_PARENT, ACTUAL_LEVEL);
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = EXPECTED_LEVEL
  WHERE LOGGER_ID = EXPECTED_LOGGER;
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE NAME = 'Test22';
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SET EXPECTED_LOGGER = -2;
SET ACTUAL_LOGGER = -1;
SET EXPECTED_PARENT = -2;
SET ACTUAL_PARENT = -1;
SET EXPECTED_LEVEL = -2;
SET ACTUAL_LEVEL = -1;
COMMIT;

-- Test23: Tests to update the level to null.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test23: Tests to update the level to null');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T23', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = NULL;
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 1;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('Test23', ACTUAL_PARENT, ACTUAL_LEVEL);
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = EXPECTED_LEVEL
  WHERE LOGGER_ID = EXPECTED_LOGGER;
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE NAME = 'Test23';
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SET EXPECTED_LOGGER = -2;
SET ACTUAL_LOGGER = -1;
SET EXPECTED_PARENT = -2;
SET ACTUAL_PARENT = -1;
SET EXPECTED_LEVEL = -2;
SET ACTUAL_LEVEL = -1;
COMMIT;

-- Test24: Tests to update root's level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test24: Tests to update root''s level');
SET EXPECTED_LOGGER = 0;
SET EXPECTED_PARENT = 2;
SET EXPECTED_LEVEL = NULL;
SET ACTUAL_PARENT = NULL;
SET ACTUAL_LEVEL = NULL;
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = EXPECTED_PARENT
  WHERE LOGGER_ID = 0;
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE NAME = 'ROOT';
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SET EXPECTED_LOGGER = -2;
SET ACTUAL_LOGGER = -1;
SET EXPECTED_PARENT = -2;
SET ACTUAL_PARENT = -1;
SET EXPECTED_LEVEL = -2;
SET ACTUAL_LEVEL = -1;
COMMIT;

-- Test25: Tests to insert second root.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test25: Tests to insert second root');
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, NULL);
IF (RAISED_LG0C1 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0C1');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0C1');
END IF;
SET RAISED_LG0C1 = FALSE;
COMMIT;

-- Test26: Tests to insert two siblings
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test26: Tests to insert two siblings');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T26', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 4;
SET ACTUAL_PARENT = 0;
SET ACTUAL_LEVEL = 4;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('test26a', ACTUAL_PARENT, ACTUAL_LEVEL);
SET ACTUAL_LEVEL = 3;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('test26b', ACTUAL_PARENT, ACTUAL_LEVEL);
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE NAME = 'test26a';
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SET EXPECTED_LOGGER = EXPECTED_LOGGER + 1;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 3;
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE NAME = 'test26b';
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SET EXPECTED_LOGGER = -2;
SET ACTUAL_LOGGER = -1;
SET EXPECTED_PARENT = -2;
SET ACTUAL_PARENT = -1;
SET EXPECTED_LEVEL = -2;
SET ACTUAL_LEVEL = -1;
COMMIT;

-- Test27: Tests to insert siblings 
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test27: Tests to insert siblings');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T27', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID() + 3;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = 2;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 4);
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('test27a', 0, 5);
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('test27b', 0, 3);
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('test27c', 0, 2);
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE NAME = 'test27c';
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SET EXPECTED_LOGGER = -2;
SET ACTUAL_LOGGER = -1;
SET EXPECTED_PARENT = -2;
SET ACTUAL_PARENT = -1;
SET EXPECTED_LEVEL = -2;
SET ACTUAL_LEVEL = -1;
COMMIT;

-- Test28: Tests to insert.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test28: Tests to insert');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T28', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID() + 2;
SET EXPECTED_PARENT = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_LEVEL = 3;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('test28a', 0, 4);
SET ACTUAL_LOGGER = GET_MAX_ID();
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('test28b', ACTUAL_LOGGER, 3);
SELECT LOGGER_ID, PARENT_ID, LEVEL_ID INTO ACTUAL_LOGGER, ACTUAL_PARENT, ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE NAME = 'test28b';
IF (EXPECTED_LOGGER <> ACTUAL_LOGGER) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LOGGER_ID ' || EXPECTED_LOGGER || ' - ' || ACTUAL_LOGGER);
END IF;
IF (EXPECTED_PARENT <> ACTUAL_PARENT) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different PARENT_ID ' || EXPECTED_PARENT || ' - ' || ACTUAL_PARENT);
END IF;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SET EXPECTED_LOGGER = -2;
SET ACTUAL_LOGGER = -1;
SET EXPECTED_PARENT = -2;
SET ACTUAL_PARENT = -1;
SET EXPECTED_LEVEL = -2;
SET ACTUAL_LEVEL = -1;
COMMIT;

-- Test29: Tests to insert a ROOT logger with a given level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test29: Tests to insert a ROOT logger with a given level');
SET EXPECTED_LEVEL = 5;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = '3'
  WHERE KEY = 'defaultRootLevelId';
CALL LOGGER.REFRESH_CONF();
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LEVEL_ID = 3
  WHERE LOGGER_ID = 0;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, EXPECTED_LEVEL);
IF (RAISED_LG0C1 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0C1');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0C1');
END IF;
SET RAISED_LG0C1 = FALSE;
COMMIT;

-- Test30: Tests to insert a ROOT logger with null level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test30: Tests to insert a ROOT logger with null level');
SET EXPECTED_LEVEL = NULL;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = '3'
  WHERE KEY = 'defaultRootLevelId';
CALL LOGGER.REFRESH_CONF();
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LEVEL_ID = 3
  WHERE LOGGER_ID = 0;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, EXPECTED_LEVEL);
IF (RAISED_LG0C1 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0C1');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0C1');
END IF;
SET RAISED_LG0C1 = FALSE;
COMMIT;

-- Test31: Tests to update a ROOT logger with a given level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test31: Tests to update a ROOT logger with a given level');
SET EXPECTED_LEVEL = 4;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = '3'
  WHERE KEY = 'defaultRootLevelId';
CALL LOGGER.REFRESH_CONF();
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LEVEL_ID = 3
  WHERE LOGGER_ID = 0;
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = EXPECTED_LEVEL
  WHERE LOGGER_ID = 0;
SELECT LEVEL_ID INTO ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID = 0;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SET EXPECTED_LEVEL = -2;
SET ACTUAL_LEVEL = -1;
COMMIT;

-- Test32: Tests to update a null ROOT logger with a given level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test32: Tests to update a null ROOT logger with a given level');
SET EXPECTED_LEVEL = 4;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = '3'
  WHERE KEY = 'defaultRootLevelId';
CALL LOGGER.REFRESH_CONF();
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LEVEL_ID = 3
  WHERE LOGGER_ID = 0;
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = EXPECTED_LEVEL
  WHERE LOGGER_ID = 0;
SELECT LEVEL_ID INTO ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID = 0;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SET EXPECTED_LEVEL = -2;
SET ACTUAL_LEVEL = -1;
COMMIT;

-- Test33: Tests to update a ROOT logger with null level
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test33: Tests to update a ROOT logger with null level');
SET EXPECTED_LEVEL = NULL;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = '3'
  WHERE KEY = 'defaultRootLevelId';
CALL LOGGER.REFRESH_CONF();
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LEVEL_ID = 3
  WHERE LOGGER_ID = 0;
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = EXPECTED_LEVEL
  WHERE LOGGER_ID = 0;
SELECT LEVEL_ID INTO ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID = 0;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SET EXPECTED_LEVEL = -2;
SET ACTUAL_LEVEL = -1;
COMMIT;

-- Test34: Tests to update a null ROOT logger with null level
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test34: Tests to update a null ROOT logger with null level');
SET EXPECTED_LEVEL = NULL;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = '3'
  WHERE KEY = 'defaultRootLevelId';
CALL LOGGER.REFRESH_CONF();
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LEVEL_ID = 3
  WHERE LOGGER_ID = 0;
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = EXPECTED_LEVEL
  WHERE LOGGER_ID = 0;
SELECT LEVEL_ID INTO ACTUAL_LEVEL
  FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID = 0;
IF (EXPECTED_LEVEL <> ACTUAL_LEVEL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID ' || EXPECTED_LEVEL || ' - ' || ACTUAL_LEVEL);
END IF;
SET EXPECTED_LEVEL = -2;
SET ACTUAL_LEVEL = -1;
COMMIT;

-- Test35: Tests Self parent
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test35: Tests Self parent');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T35', 0, 0);
SET EXPECTED_LOGGER = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = NULL;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (EXPECTED_LOGGER, 'test35', EXPECTED_LOGGER, EXPECTED_LEVEL);
IF (RAISED_LG0C5 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0C5');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0C5');
END IF;
SET RAISED_LG0C5 = FALSE;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
COMMIT;

-- Test36: Tests double same child.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Test36: Tests double same child');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
SET EXPECTED_PARENT = 0;
SET EXPECTED_LEVEL = NULL;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('test36', EXPECTED_PARENT, EXPECTED_LEVEL);
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('test36', EXPECTED_PARENT, EXPECTED_LEVEL);
IF (RAISED_LG0C6 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0C6');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0C6');
END IF;
SET RAISED_LG0C6 = FALSE;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
COMMIT;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsConfLogger: Cleaning environment');
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = 'true'
  WHERE KEY = 'internalCache';
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = 'false'
  WHERE KEY = 'logInternals';
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsConfLogger: Finished succesfully');
COMMIT;

END @

DROP FUNCTION GET_MAX_ID @

--SELECT LOGGER_ID, VARCHAR(NAME, 32), PARENT_ID, LEVEL_ID
--  FROM LOGDATA.CONF_LOGGERS
--  ORDER BY LOGGER_ID @

