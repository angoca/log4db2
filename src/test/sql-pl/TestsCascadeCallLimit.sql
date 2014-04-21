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
 * Version: 2014-04-21 1-Beta
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOGGER_1B @

SET PATH = SYSPROC, LOGGER_1B @

CREATE OR REPLACE PROCEDURE LOGGING (
  IN VAL SMALLINT,
  IN LEVEL SMALLINT,
  IN LIMIT SMALLINT)
 BEGIN
  DECLARE MESSAGE ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE STMT STATEMENT;

  -- TODO Fails when using Temporal capabilities.
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
     SET MESSAGE = 'Cascade call for "LOGGING" enters with ' || COALESCE(VAL, -1);
     CALL LOGGER.LOG(0, 3, MESSAGE);
     -- TODO The next line raises an error.
     -- CALL LOGGER.LOG(0, 3, 'Cascade call for "LOGGING" enters with ' || COALESCE(VAL, -1));
    END CASE;
   COMMIT;
  ELSE
   PREPARE STMT FROM 'CALL LOGGING(?, ?, ?)';
   EXECUTE STMT USING VAL + 1, LEVEL, LIMIT;
  END IF;
 END @

-- TODO The same with a function.

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

DECLARE CASCADE SMALLINT; -- Cascade calls.
DECLARE MIN_61A SMALLINT DEFAULT 61;
DECLARE MIN_61 SMALLINT DEFAULT 61;
DECLARE VAL_62 SMALLINT DEFAULT 62;
DECLARE MIN_63 SMALLINT DEFAULT 63;
DECLARE RAISED_LG001 BOOLEAN DEFAULT FALSE; -- Just one ROOT.
DECLARE RAISED_724 BOOLEAN DEFAULT FALSE; -- Null value.
DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
  SET RAISED_LG001 = TRUE;
DECLARE CONTINUE HANDLER FOR SQLSTATE '54038'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_724 = TRUE;
  END;

  -- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsCascadeCallLimit: Preparing environment');
SET RAISED_LG001 = FALSE;
SET RAISED_724 = FALSE;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
UPDATE LOGDATA.CONF_LOGGERS
  SET LEVEL_ID = 5
  WHERE LOGGER_ID = 0;
COMMIT;

-- Test01: Limit logging to ROOT with fatal.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test01: Limit logging to ROOT with fatal');
SET EXPECTED = 'TRUE';
SET CASCADE = VAL_62;
CALL LOGGING(1, 1, CASCADE);
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE = 'LG001. Cascade call limit achieved, for FATAL: (0) Cascade call for "LOGGING" enters with ' || CASCADE
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (ACTUAL IS NULL OR EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || COALESCE(ACTUAL, 'NULL'));
END IF;
COMMIT;

-- Test02: Limit achieved logging to ROOT with fatal.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test02: Limit achieved logging to ROOT with fatal');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_61A;
CALL LOGGING(1, 1, CASCADE);
IF (RAISED_LG001 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised LG001');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
END IF;
SET RAISED_LG001 = FALSE;
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for LOG: Cascade call for "LOGGING" enters w%'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS)
  AND LEVEL_ID = 1;
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test03: Limit passed logging to ROOT with fatal.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test03: Limit passed logging to ROOT with fatal');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_61;
CALL LOGGING(1, 1, CASCADE);
IF (RAISED_LG001 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised LG001');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
END IF;
SET RAISED_LG001 = FALSE;
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for FATAL: (0) Cascade call for "LOGGING" en%'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || ACTUAL);
END IF;
DELETE FROM LOGS L
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieve, for %';
COMMIT;

-- Test04: Cascade call limit with fatal.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test04: Cascade call limit with fatal');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_63;
CALL LOGGING(1, 1, CASCADE);
IF (RAISED_724 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised 54038');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 54038');
END IF;
SET RAISED_724 = FALSE;
COMMIT;

-- Test05: Limit logging to ROOT with error.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test05: Limit logging to ROOT with error');
SET EXPECTED = 'TRUE';
SET CASCADE = VAL_62;
CALL LOGGING(1, 2, CASCADE);
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE = 'LG001. Cascade call limit achieved, for ERROR: (0) Cascade call for "LOGGING" enters with ' || CASCADE
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (ACTUAL IS NULL OR EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || COALESCE(ACTUAL, 'NULL'));
END IF;
COMMIT;

-- Test06: Limit achieved logging to ROOT with error.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test06: Limit achieved logging to ROOT with error');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_61A;
CALL LOGGING(1, 2, CASCADE);
IF (RAISED_LG001 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised LG001');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
END IF;
SET RAISED_LG001 = FALSE;
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for LOG: Cascade call for "LOGGING" enters w%'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS)
  AND LEVEL_ID = 2;
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test07: Limit passed logging to ROOT with error.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test07: Limit passed logging to ROOT with error');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_61;
CALL LOGGING(1, 2, CASCADE);
IF (RAISED_LG001 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised LG001');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
END IF;
SET RAISED_LG001 = FALSE;
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for ERROR: (0) Cascade call for "LOGGING" en%'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || ACTUAL);
END IF;
DELETE FROM LOGS L
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieve, for %';
COMMIT;

-- Test08: Cascade call limit with error.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test08: Cascade call limit with error');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_63;
CALL LOGGING(1, 2, CASCADE);
IF (RAISED_724 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised 54038');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 54038');
END IF;
SET RAISED_724 = FALSE;
COMMIT;

-- Test09: Limit logging to ROOT with warn.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test09: Limit logging to ROOT with warn');
SET EXPECTED = 'TRUE';
SET CASCADE = VAL_62;
CALL LOGGING(1, 3, CASCADE);
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE = 'LG001. Cascade call limit achieved, for WARN: (0) Cascade call for "LOGGING" enters with ' || CASCADE
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (ACTUAL IS NULL OR EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || COALESCE(ACTUAL, 'NULL'));
END IF;
COMMIT;

-- Test10: Limit achieved logging to ROOT with warn.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test10: Limit achieved logging to ROOT with warn');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_61A;
CALL LOGGING(1, 3, CASCADE);
IF (RAISED_LG001 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised LG001');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
END IF;
SET RAISED_LG001 = FALSE;
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for LOG: Cascade call for "LOGGING" enters w%'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS)
  AND LEVEL_ID = 3;
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test11: Limit passed logging to ROOT with warn.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test11: Limit passed logging to ROOT with warn');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_61;
CALL LOGGING(1, 3, CASCADE);
IF (RAISED_LG001 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised LG001');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
END IF;
SET RAISED_LG001 = FALSE;
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for WARN: (0) Cascade call for "LOGGING" en%'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || ACTUAL);
END IF;
DELETE FROM LOGS L
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieve, for %';
COMMIT;

-- Test12: Cascade call limit with warn.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test12: Cascade call limit with warn');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_63;
CALL LOGGING(1, 3, CASCADE);
IF (RAISED_724 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised 54038');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 54038');
END IF;
SET RAISED_724 = FALSE;
COMMIT;

-- Test13: Limit logging to ROOT with info.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test13: Limit logging to ROOT with info');
SET EXPECTED = 'TRUE';
SET CASCADE = VAL_62;
CALL LOGGING(1, 4, CASCADE);
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE = 'LG001. Cascade call limit achieved, for INFO: (0) Cascade call for "LOGGING" enters with ' || CASCADE
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (ACTUAL IS NULL OR EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test14: Limit achieved logging to ROOT with info.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test14: Limit achieved logging to ROOT with info');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_61A;
CALL LOGGING(1, 4, CASCADE);
IF (RAISED_LG001 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised LG001');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
END IF;
SET RAISED_LG001 = FALSE;
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for LOG: Cascade call for "LOGGING" enters w%'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test15: Limit passed logging to ROOT with info.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test15: Limit passed logging to ROOT with info');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_61;
CALL LOGGING(1, 4, CASCADE);
IF (RAISED_LG001 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised LG001');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
END IF;
SET RAISED_LG001 = FALSE;
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for INFO: (0) Cascade call for "LOGGING" en%'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || ACTUAL);
END IF;
DELETE FROM LOGS L
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieve, for %';
COMMIT;

-- Test16: Cascade call limit with info.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test16: Cascade call limit with info');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_63;
CALL LOGGING(1, 4, CASCADE);
IF (RAISED_724 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised 54038');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 54038');
END IF;
SET RAISED_724 = FALSE;
COMMIT;

-- Test17: Limit logging to ROOT with debug.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test17: Limit logging to ROOT with debug');
SET EXPECTED = 'TRUE';
SET CASCADE = VAL_62;
CALL LOGGING(1, 5, CASCADE);
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE = 'LG001. Cascade call limit achieved, for DEBUG: (0) Cascade call for "LOGGING" enters with ' || CASCADE
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (ACTUAL IS NULL OR EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || COALESCE(ACTUAL, 'NULL'));
END IF;
COMMIT;

-- Test18: Limit achieved logging to ROOT with debug.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test18: Limit achieved logging to ROOT with debug');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_61A;
CALL LOGGING(1, 5, CASCADE);
IF (RAISED_LG001 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised LG001');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
END IF;
SET RAISED_LG001 = FALSE;
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for LOG: Cascade call for "LOGGING" enters w%'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test19: Limit passed logging to ROOT with debug.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test19: Limit passed logging to ROOT with debug');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_61;
CALL LOGGING(1, 5, CASCADE);
IF (RAISED_LG001 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised LG001');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
END IF;
SET RAISED_LG001 = FALSE;
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for DEBUG: (0) Cascade call for "LOGGING" en%'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || ACTUAL);
END IF;
DELETE FROM LOGS L
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieve, for %';
COMMIT;

-- Test20: Cascade call limit with debug.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test20: Cascade call limit with debug');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_63;
CALL LOGGING(1, 5, CASCADE);
IF (RAISED_724 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised 54038');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 54038');
END IF;
SET RAISED_724 = FALSE;
COMMIT;

-- Test21: Limit logging to ROOT with default.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test21: Limit logging to ROOT with default');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_61A;
CALL LOGGING(1, -1, CASCADE);
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE = '[WARN ] ROOT - Cascade call for "LOGGING" enters with ' || CASCADE
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test22: Limit passed logging to ROOT with default.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test22: Limit passed logging to ROOT with default');
SET EXPECTED = 'TRUE';
SET CASCADE = VAL_62;
CALL LOGGING(1, -1, CASCADE);
IF (RAISED_LG001 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised LG001');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
END IF;
SET RAISED_LG001 = FALSE;
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for LOG: Cascade call for "LOGGING" enters w%'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || ACTUAL);
END IF;
DELETE FROM LOGS L
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieve, for %';
COMMIT;

-- Test23: Cascade call limit with default.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test23: Cascade call limit with default');
SET EXPECTED = 'TRUE';
SET CASCADE = MIN_63;
CALL LOGGING(1, -1, CASCADE);
IF (RAISED_724 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised 54038');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 54038');
END IF;
SET RAISED_724 = FALSE;
COMMIT;

-- Test24: Limit logging to ROOT 60.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test24: Limit logging to ROOT 60');
SET EXPECTED = 'TRUE';
SET CASCADE = 60;
CALL LOGGING(1, 1, CASCADE);
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE = 'LG001. Cascade call limit achieved, for LOG: Cascade call for "LOGGING" enters with ' || CASCADE
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (ACTUAL IS NULL OR EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || COALESCE(ACTUAL, 'NULL'));
END IF;
COMMIT;

-- Test25: Limit logging to ROOT 61.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test25: Limit logging to ROOT 61');
SET EXPECTED = 'TRUE';
SET CASCADE = 61;
CALL LOGGING(1, 1, CASCADE);
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE = 'LG001. Cascade call limit achieved, for LOG: Cascade call for "LOGGING" enters with ' || CASCADE
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (ACTUAL IS NULL OR EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED || ' - ' || COALESCE(ACTUAL, 'NULL'));
END IF;
COMMIT;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsCascadeCallLimit: Cleaning environment');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
UPDATE LOGS SET LEVEL_ID = 5 WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved%';
UPDATE LOGS SET LEVEL_ID = 5 WHERE MESSAGE LIKE 'ROOT - Cascade call for "LOGGING" enters with ';
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsCascadeCallLimit: Finished succesfully');
COMMIT;

END @

DROP PROCEDURE LOGGING @

