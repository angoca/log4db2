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
 * Version: 2014-04-21 1-Beta
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOGGER_1B @

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '0000';

DECLARE RAISED_LG0L1 BOOLEAN DEFAULT FALSE; -- Negative level.
DECLARE RAISED_LG0L2 BOOLEAN DEFAULT FALSE; -- Not sequence.
DECLARE RAISED_LG0L3 BOOLEAN DEFAULT FALSE; -- Level id.
DECLARE RAISED_LG0L4 BOOLEAN DEFAULT FALSE; -- Minimal value.
DECLARE RAISED_LG0L5 BOOLEAN DEFAULT FALSE; -- Delete.
DECLARE RAISED_407 BOOLEAN DEFAULT FALSE; -- Null value.
DECLARE RAISED_803 BOOLEAN DEFAULT FALSE; -- Duplicated key.
DECLARE ACTUAL_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
DECLARE ACTUAL_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;
DECLARE EXPECTED_LEVEL_ID ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
DECLARE EXPECTED_NAME ANCHOR DATA TYPE TO LOGDATA.LEVELS.NAME;

-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0L1'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0L1 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0L2'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0L2 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0L3'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0L3 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0L4'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0L4 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0L5'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0L5 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE '23502'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_407 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE '23505'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (1, 'SQLState ' || SQLSTATE);
   SET RAISED_803 = TRUE;
  END;

-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'TestsLevels: Preparing environment');
SET RAISED_LG0L1 = FALSE;
SET RAISED_LG0L2 = FALSE;
SET RAISED_LG0L3 = FALSE;
SET RAISED_LG0L4 = FALSE;
SET RAISED_LG0L5 = FALSE;
SET RAISED_407 = FALSE;
SET RAISED_803 = FALSE;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
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
COMMIT;

-- Test01: Inserts a new level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test01: Inserts a new level');
SET EXPECTED_LEVEL_ID = 1;
SET EXPECTED_NAME = 'ON';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, EXPECTED_NAME);
SELECT LEVEL_ID, NAME INTO EXPECTED_LEVEL_ID, EXPECTED_NAME
  FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
IF (EXPECTED_LEVEL_ID <> ACTUAL_LEVEL_ID) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2,  EXPECTED_LEVEL_ID || ' - ' || ACTUAL_LEVEL_ID);
END IF;
IF (EXPECTED_NAME <> ACTUAL_NAME) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different NAME');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2,  EXPECTED_NAME || ' - ' || ACTUAL_NAME);
END IF;
COMMIT;

-- Test02: Inserts a new level with null name.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test02: Inserts a new level with null name');
SET EXPECTED_LEVEL_ID = 1;
SET EXPECTED_NAME = NULL;
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, EXPECTED_NAME);
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised 23502');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 23502');
END IF;
SET RAISED_407 = FALSE;
COMMIT;

-- Test03: Inserts a new level with null id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test03: Inserts a new level with null id');
SET EXPECTED_LEVEL_ID = NULL;
SET EXPECTED_NAME = 'ON';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, EXPECTED_NAME);
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised 23502');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 23502');
END IF;
SET RAISED_407 = FALSE;
COMMIT;

-- Test04: Inserts a new level with negative id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test04: Inserts a new level with negative id');
SET EXPECTED_LEVEL_ID = -1;
SET EXPECTED_NAME = 'test4';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, EXPECTED_NAME);
IF (RAISED_LG0L1 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0L1');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0L1');
END IF;
SET RAISED_LG0L1 = FALSE;
COMMIT;

-- Test05: Inserts a new level with duplicated 0.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test05: Inserts a new level with duplicated 0');
SET EXPECTED_LEVEL_ID = 0;
SET EXPECTED_NAME = 'test5';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, EXPECTED_NAME);
IF (RAISED_LG0L2 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0L2');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0L2');
END IF;
SET RAISED_LG0L2 = FALSE;
COMMIT;

-- Test06: Inserts a new level with duplicated id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test06: Inserts a new level with duplicated id');
SET EXPECTED_LEVEL_ID = 1;
SET EXPECTED_NAME = 'test6';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, EXPECTED_NAME);
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, EXPECTED_NAME);
IF (RAISED_LG0L2 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0L2');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0L2');
END IF;
SET RAISED_LG0L2 = FALSE;
COMMIT;

-- Test07: Inserts three level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test07: Inserts three level');
SET EXPECTED_LEVEL_ID = 4;
SET EXPECTED_NAME = 'C3';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (1, 'A1');
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (2, 'B2');
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (3, 'C3');
SELECT LEVEL_ID, NAME INTO EXPECTED_LEVEL_ID, EXPECTED_NAME
  FROM LOGDATA.LEVELS
  WHERE LEVEL_ID = (SELECT MAX(LEVEL_ID) FROM LOGDATA.LEVELS);
IF (EXPECTED_LEVEL_ID <> ACTUAL_LEVEL_ID) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2,  EXPECTED_LEVEL_ID || ' - ' || ACTUAL_LEVEL_ID);
END IF;
IF (EXPECTED_NAME <> ACTUAL_NAME) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different NAME');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2,  EXPECTED_NAME || ' - ' || ACTUAL_NAME);
END IF;
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID = 3;
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID = 2;
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID = 1;
COMMIT;

-- Test08: Updates a level name.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test08: Updates a level name');
SET EXPECTED_LEVEL_ID = 1;
SET EXPECTED_NAME = 'ON';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, 'on');
UPDATE LOGDATA.LEVELS
  SET NAME = EXPECTED_NAME
  WHERE LEVEL_ID = EXPECTED_LEVEL_ID;
SELECT LEVEL_ID, NAME INTO EXPECTED_LEVEL_ID, EXPECTED_NAME
  FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
IF (EXPECTED_LEVEL_ID <> ACTUAL_LEVEL_ID) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2,  EXPECTED_LEVEL_ID || ' - ' || ACTUAL_LEVEL_ID);
END IF;
IF (EXPECTED_NAME <> ACTUAL_NAME) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different NAME');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2,  EXPECTED_NAME || ' - ' || ACTUAL_NAME);
END IF;
COMMIT;

-- Test09: Updates a level id to 0.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test09: Updates a id to 0');
SET EXPECTED_LEVEL_ID = 1;
SET EXPECTED_NAME = 'ON';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, EXPECTED_NAME);
UPDATE LOGDATA.LEVELS
  SET LEVEL_ID = 0
  WHERE LEVEL_ID = EXPECTED_LEVEL_ID;
IF (RAISED_LG0L3 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0L3');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0L3');
END IF;
SET RAISED_LG0L3 = FALSE;
COMMIT;

-- Test10: Updates a level name.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test10: Updates a name');
SET EXPECTED_LEVEL_ID = 2;
SET EXPECTED_NAME = 'b2';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (1, 'a1');
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, EXPECTED_NAME);
UPDATE LOGDATA.LEVELS
  SET NAME = 'a1'
  WHERE LEVEL_ID = EXPECTED_LEVEL_ID;
BEGIN
 DECLARE CNT SMALLINT;
 SELECT COUNT(NAME) INTO CNT
   FROM LOGDATA.LEVELS
   WHERE LEVEL_ID <> 0
   GROUP BY NAME;
 IF (CNT <> 2) THEN
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different CNT');
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2,  EXPECTED_LEVEL_ID || ' - ' || ACTUAL_LEVEL_ID);
 END IF;
END;
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID = 2;
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID = 1;
COMMIT;

-- Test11: Updates a level name to off.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test11: Updates a name to off');
SET EXPECTED_LEVEL_ID = 1;
SET EXPECTED_NAME = 'off';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, 'a1');
UPDATE LOGDATA.LEVELS
  SET NAME = EXPECTED_NAME
  WHERE LEVEL_ID = EXPECTED_LEVEL_ID;
BEGIN
 DECLARE CNT SMALLINT;
 SELECT COUNT(NAME) INTO CNT
   FROM LOGDATA.LEVELS
   WHERE NAME = EXPECTED_NAME
   GROUP BY NAME;
 IF (CNT <> 2) THEN
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different CNT');
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2,  EXPECTED_LEVEL_ID || ' - ' || ACTUAL_LEVEL_ID);
 END IF;
END;
COMMIT;

-- Test12: Updates a level id to existant.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test12: Updates a id to existant');
SET EXPECTED_LEVEL_ID = 2;
SET EXPECTED_NAME = 'b';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (1, 'a');
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, EXPECTED_NAME);
UPDATE LOGDATA.LEVELS
  SET LEVEL_ID = 1
  WHERE LEVEL_ID = EXPECTED_LEVEL_ID;
IF (RAISED_LG0L3 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0L3');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0L3');
END IF;
SET RAISED_LG0L3 = FALSE;
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID = 2;
COMMIT;

-- Test13: Updates a level id to negative.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test13: Updates a id to negative');
SET EXPECTED_LEVEL_ID = 1;
SET EXPECTED_NAME = 'ON';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, EXPECTED_NAME);
UPDATE LOGDATA.LEVELS
  SET LEVEL_ID = -1
  WHERE LEVEL_ID = EXPECTED_LEVEL_ID;
IF (RAISED_LG0L3 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0L3');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0L3');
END IF;
SET RAISED_LG0L3 = FALSE;
COMMIT;

-- Test14: Updates a level id to null.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test14: Updates a id to null');
SET EXPECTED_LEVEL_ID = 1;
SET EXPECTED_NAME = 'ON';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (EXPECTED_LEVEL_ID, EXPECTED_NAME);
UPDATE LOGDATA.LEVELS
  SET LEVEL_ID = NULL
  WHERE LEVEL_ID = EXPECTED_LEVEL_ID;
IF (RAISED_LG0L3 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0L3');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0L3');
END IF;
SET RAISED_LG0L3 = FALSE;
COMMIT;

-- Test15: Deletes a level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test15: Deletes a level');
SET EXPECTED_LEVEL_ID = 0;
SET EXPECTED_NAME = 'off';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (1, 'ON');
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID = 1;
SELECT LEVEL_ID, NAME INTO EXPECTED_LEVEL_ID, EXPECTED_NAME
  FROM LOGDATA.LEVELS
  WHERE LEVEL_ID = (SELECT MAX(LEVEL_ID) FROM LOGDATA.LEVELS);
IF (EXPECTED_LEVEL_ID <> ACTUAL_LEVEL_ID) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different LEVEL_ID');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2,  EXPECTED_LEVEL_ID || ' - ' || ACTUAL_LEVEL_ID);
END IF;
IF (EXPECTED_NAME <> ACTUAL_NAME) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different NAME');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2,  EXPECTED_NAME || ' - ' || ACTUAL_NAME);
END IF;
COMMIT;

-- Test16: Deletes a medium level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test16: Deletes a medium level');
SET EXPECTED_LEVEL_ID = 0;
SET EXPECTED_NAME = 'off';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (1, 'A1');
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (2, 'B2');
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID = 1;
IF (RAISED_LG0L5 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0L5');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0L5');
END IF;
SET RAISED_LG0L5 = FALSE;
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID = 2;
COMMIT;

-- Test17: Deletes a minimal level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test17: Deletes a minimal level');
SET EXPECTED_LEVEL_ID = 0;
SET EXPECTED_NAME = 'off';
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID <> 0;
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (1, 'A1');
INSERT INTO LOGDATA.LEVELS (LEVEL_ID, NAME) VALUES (2, 'B2');
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID = 0;
IF (RAISED_LG0L4 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised LG0L4');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0L4');
END IF;
SET RAISED_LG0L4 = FALSE;
DELETE FROM LOGDATA.LEVELS
  WHERE LEVEL_ID = 2;
COMMIT;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsLevels: Cleaning environment');
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
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsLevels: Finished succesfully');
COMMIT;

END @

--SELECT *
--  FROM LOGDATA.LEVELS @

