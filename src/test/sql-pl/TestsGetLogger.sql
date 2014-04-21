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
 * Tests different names for loggers.
 *
 * Version: 2014-04-21 1-Beta
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOGGER_1B @

SET PATH = SYSPROC, LOGGER_1B @

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

DECLARE STRING ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
DECLARE EXPECTED_ID ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE ACTUAL_ID ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;

-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 4, 'Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 4, 'Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 5, 'Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'TestsGetLogger: Preparing environment');
DELETE FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID <> 0;
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = 'false'
  WHERE KEY = 'internalCache';
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = 'false'
  WHERE KEY = 'logInternals';
CALL LOGGER.REFRESH_CACHE();
COMMIT;

-- Test01: empty string.
SET STRING = '';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test01: >' || STRING || '<');
SET EXPECTED_ID = 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test02: a whitespace.
SET STRING = ' ';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test02: >' || STRING || '<');
SET EXPECTED_ID = 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test03: a dot.
SET STRING = '.';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test03: >' || STRING || '<');
SET EXPECTED_ID = 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test04: two dots.
SET STRING = '..';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test04: >' || STRING || '<');
SET EXPECTED_ID = 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test05: a letter.
SET STRING = 'a';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test05: >' || STRING || '<');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T5', 0, 0);
SET EXPECTED_ID = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test06: a letter followed by a dot.
SET STRING = 'b.';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test06: >' || STRING || '<');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T6', 0, 0);
SET EXPECTED_ID = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test07: two valid levels.
SET STRING = 'c.c';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test07: >' || STRING || '<');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T7', 0, 0);
SET EXPECTED_ID = GET_MAX_ID() + 2;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test08: a dot preceded by a dot.
SET STRING = '.d';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test08: >' || STRING || '<');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T8', 0, 0);
SET EXPECTED_ID = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test09: a letter surrrounded by dots.
SET STRING = '.e.';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test09: >' || STRING || '<');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T9', 0, 0);
SET EXPECTED_ID = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test10: three valid levels.
SET STRING = 'f.g.h';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test10: >' || STRING || '<');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T10', 0, 0);
SET EXPECTED_ID = GET_MAX_ID() + 3;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test11: three valid levels (multiple letters).
SET STRING = 'ii.jj.kk';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test11: >' || STRING || '<');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T11', 0, 0);
SET EXPECTED_ID = GET_MAX_ID() + 3;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test12: a multi letter level.
SET STRING = 'lll';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test12: >' || STRING || '<');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T12', 0, 0);
SET EXPECTED_ID = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test13: two multi letters levels.
SET STRING = 'mm.nn';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test13: >' || STRING || '<');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T13', 0, 0);
SET EXPECTED_ID = GET_MAX_ID() + 2;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test14: three multi letters levels.
SET STRING = '111.222.333';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test14: >' || STRING || '<');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T14', 0, 0);
SET EXPECTED_ID = GET_MAX_ID() + 3;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test15: a letter surrrounded by spaces.
SET STRING = ' p ';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test15: >' || STRING || '<');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T15', 0, 0);
SET EXPECTED_ID = GET_MAX_ID() + 1;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test16: a null string.
SET STRING = NULL;
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test16: >' || COALESCE(STRING, 'NULL') || '<');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T16', 0, 0);
SET EXPECTED_ID = 0;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || COALESCE(STRING, 'NULL'));
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test17: Before limit.
SET STRING = '1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test17: Before limit >' || STRING || '<');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T17', 0, 0);
SET EXPECTED_ID = GET_MAX_ID() + 30;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
COMMIT;

-- Test18: Limit.
SET STRING = '1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1';
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test18: Limit >' || STRING || '<');
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('T18', 0, 0);
SET EXPECTED_ID = 0;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID <> 0;
CALL LOGGER.GET_LOGGER(STRING, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || STRING);
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,-1));
END IF;
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE LIKE 'LG001. Cascade call limit achieved, for GET_LOGGER:%'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'TestsGetLogger: Cleaning environment');
DELETE FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID <> 0;
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE)
  VALUES ('autonomousLogging', 'true'),
         ('defaultRootLevelId', '3'),
         ('internalCache', 'true'),
         ('logInternals', 'false'),
         ('secondsToRefresh', '30');
CALL LOGGER.REFRESH_CACHE ();
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'TestsGetLogger: Finished succesfully');
COMMIT;

END @

-- SELECT LOGGER_ID, VARCHAR(NAME,32), PARENT_ID, LEVEL_ID FROM LOGDATA.CONF_LOGGERS @

DROP FUNCTION GET_MAX_ID @

