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
 * Tests for the references table.
 */

SET CURRENT SCHEMA LOGGER_1A @

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

DECLARE LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE LOGGER_ID_PARENT ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE LOGGER_NAME ANCHOR LOGDATA.CONF_LOGGERS.NAME;
DECLARE EXPECTED_QTY SMALLINT;
DECLARE ACTUAL_QTY SMALLINT;
DECLARE LAST_CONF_APPENDER_ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;

/*DECLARE CONTINUE HANDLER FOR SQLSTATE '23503'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) 
     VALUES (1, 'Error: logger_id:' || COALESCE(LOGGER_ID,-1) || '-conf_appender_id:' || COALESCE(LAST_CONF_APPENDER_ID,-1));
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) 
     VALUES (1, 'logger_id:' || (select max(logger_id) from logdata.conf_loggers));
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) 
     VALUES (1, 'conf_appender_id:' || (select max(ref_id) from logdata.conf_appenders));
  END;
*/
-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'TestsReferences: Preparing environment');
DELETE FROM LOGDATA.REFERENCES;
COMMIT;

-- Test1: Tries to log when references is empty.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test1: Tries to log when references is empty');
DELETE FROM LOGDATA.REFERENCES;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 5);
CALL LOGGER.GET_LOGGER('References-Test1', LOGGER_ID);
SET EXPECTED_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS);
CALL LOGGER.INFO(LOGGER_ID, 'Message test');
SET ACTUAL_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS);
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES 
   (GENERATE_UNIQUE(), 2, 'Different qty, expected ' || COALESCE(EXPECTED_QTY, -1) || ' actual ' || COALESCE(ACTUAL_QTY,-1));
END IF;
COMMIT;

-- Test2: Writes one log.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test2: Writes one log');
DELETE FROM LOGDATA.REFERENCES;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 5);
SET LOGGER_NAME = 'References-Test2';
CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (LOGGER_ID, LOGGER_NAME, 0, 5);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (LOGGER_ID, (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS));
SET EXPECTED_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS) + 1;
CALL LOGGER.INFO(LOGGER_ID, 'Message test');
SET ACTUAL_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS);
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES 
   (GENERATE_UNIQUE(), 2, 'Different qty, expected ' || COALESCE(EXPECTED_QTY, -1) || ' actual ' || COALESCE(ACTUAL_QTY,-1));
END IF;
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE LIKE '%INFO%' 
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Test3: Writes the same log twice (Root and another).
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test3: Writes the same log twice');
DELETE FROM LOGDATA.REFERENCES;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 5);
SET LOGGER_NAME = 'References-Test2';
CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (LOGGER_ID, LOGGER_NAME, 0, 5);
SET LAST_CONF_APPENDER_ID = (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (LOGGER_ID, LAST_CONF_APPENDER_ID);
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
  VALUES ('More DB2 Tables', 1, NULL, '{%p} %c : %m');
SET LAST_CONF_APPENDER_ID = (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (LOGGER_ID, LAST_CONF_APPENDER_ID);
SET EXPECTED_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS) + 2;
CALL LOGGER.INFO(LOGGER_ID, 'Message test');
SET ACTUAL_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS);
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES 
   (GENERATE_UNIQUE(), 2, 'Different qty, expected ' || COALESCE(EXPECTED_QTY, -1) || ' actual ' || COALESCE(ACTUAL_QTY,-1));
END IF;
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE LIKE '%INFO%' 
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE LIKE '%INFO%' 
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Test4: Non-root logger as only logger in references.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test4: Non-root logger as only logger in references');
DELETE FROM LOGDATA.REFERENCES;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE WHERE LOGGER_ID <> 0;
DELETE FROM LOGDATA.CONF_APPENDERS;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 5);
SET LOGGER_NAME = 'Test4';
CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (LOGGER_ID, LOGGER_NAME, 0, 1);
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
  VALUES ('More DB2 Tables-4', 1, NULL, '{%p} %c : %m');
SET LAST_CONF_APPENDER_ID = (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (LOGGER_ID, LAST_CONF_APPENDER_ID);
SET EXPECTED_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS);
CALL LOGGER.INFO(LOGGER_ID, 'Message test');
SET ACTUAL_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS);
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES 
   (GENERATE_UNIQUE(), 2, 'Different qty, expected ' || COALESCE(EXPECTED_QTY, -1) || ' actual ' || COALESCE(ACTUAL_QTY,-1));
END IF;
DELETE FROM LOGDATA.REFERENCES WHERE LOGGER_ID = LOGGER_ID;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID = LOGGER_ID;
DELETE FROM LOGDATA.CONF_APPENDERS WHERE REF_ID = LAST_CONF_APPENDER_ID;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 3);
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
  VALUES ('DB2 Tables', 1, NULL, '[%p] %c - %m');
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS));
COMMIT;

-- Test5: Non-root logger as only logger in references - logs.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test5: Non-root logger as only logger in references - logs');
DELETE FROM LOGDATA.REFERENCES;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE WHERE LOGGER_ID <> 0;
DELETE FROM LOGDATA.CONF_APPENDERS;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 5);
SET LOGGER_NAME = 'Test5';
CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (LOGGER_ID, LOGGER_NAME, 0, 5);
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
  VALUES ('More DB2 Tables-5', 1, NULL, '(%p) %c : %m');
SET LAST_CONF_APPENDER_ID = (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (LOGGER_ID, LAST_CONF_APPENDER_ID);
SET EXPECTED_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS) + 1;
CALL LOGGER.INFO(LOGGER_ID, 'Message test');
SET ACTUAL_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS);
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES 
   (GENERATE_UNIQUE(), 2, 'Different qty, expected ' || COALESCE(EXPECTED_QTY, -1) || ' actual ' || COALESCE(ACTUAL_QTY,-1));
END IF;
DELETE FROM LOGDATA.REFERENCES WHERE LOGGER_ID = LOGGER_ID;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID = LOGGER_ID;
DELETE FROM LOGDATA.CONF_APPENDERS WHERE REF_ID = LAST_CONF_APPENDER_ID;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 3);
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
  VALUES ('DB2 Tables', 1, NULL, '[%p] %c - %m');
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS));
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE LIKE '%INFO%' 
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Test6: Root logger configured but not logs. Other logger does.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test6: Root logger configured but not logs. Other logger does.');
DELETE FROM LOGDATA.REFERENCES;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE WHERE LOGGER_ID <> 0;
DELETE FROM LOGDATA.CONF_APPENDERS;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 5);
SET LOGGER_NAME = 'Test6';
CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (LOGGER_ID, LOGGER_NAME, 0, 5);
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
  VALUES ('More DB2 Tables-6.1', 1, NULL, '1: (%p) %c : %m');
SET LAST_CONF_APPENDER_ID = (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (LOGGER_ID, LAST_CONF_APPENDER_ID);
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
  VALUES ('More DB2 Tables-6.2', 1, NULL, '2: (%p) %c : %m');
SET LAST_CONF_APPENDER_ID = (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (LOGGER_ID, LAST_CONF_APPENDER_ID);
SET EXPECTED_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS) + 2;
CALL LOGGER.INFO(LOGGER_ID, 'Message test');
SET ACTUAL_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS);
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES 
   (GENERATE_UNIQUE(), 2, 'Different qty, expected ' || COALESCE(EXPECTED_QTY, -1) || ' actual ' || COALESCE(ACTUAL_QTY,-1));
END IF;
DELETE FROM LOGDATA.REFERENCES WHERE LOGGER_ID = LOGGER_ID;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID = LOGGER_ID;
DELETE FROM LOGDATA.CONF_APPENDERS WHERE REF_ID = LAST_CONF_APPENDER_ID;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 3);
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
  VALUES ('DB2 Tables', 1, NULL, '[%p] %c - %m');
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS));
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE LIKE '%INFO%' 
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE LIKE '%INFO%' 
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Test7: Root off. Other off, and another on.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test7: Root off. Other off, and another on');
DELETE FROM LOGDATA.REFERENCES;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE WHERE LOGGER_ID <> 0;
DELETE FROM LOGDATA.CONF_APPENDERS;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 5);
SET LOGGER_NAME = 'Test7-1';
CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (LOGGER_ID, LOGGER_NAME, 0, 5);
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
  VALUES ('More DB2 Tables-7.1', 1, NULL, '[[%p]] %c : %m');
SET LAST_CONF_APPENDER_ID = (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (LOGGER_ID, LAST_CONF_APPENDER_ID);
SET LOGGER_NAME = 'Test7-2';
CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (LOGGER_ID, LOGGER_NAME, 0, 5);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (LOGGER_ID, LAST_CONF_APPENDER_ID);
SET EXPECTED_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS) + 1;
CALL LOGGER.INFO(LOGGER_ID, 'Message test');
SET ACTUAL_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS);
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES 
   (GENERATE_UNIQUE(), 2, 'Different qty, expected ' || COALESCE(EXPECTED_QTY, -1) || ' actual ' || COALESCE(ACTUAL_QTY,-1));
END IF;
DELETE FROM LOGDATA.REFERENCES WHERE LOGGER_ID = LOGGER_ID;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID = LOGGER_ID;
DELETE FROM LOGDATA.CONF_APPENDERS WHERE REF_ID = LAST_CONF_APPENDER_ID;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 3);
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
  VALUES ('DB2 Tables', 1, NULL, '[%p] %c - %m');
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS));
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE LIKE '%INFO%' 
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Test8: Root off and other on, but son of the other is on.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test8: Root off and other on, but son of the other is on');
DELETE FROM LOGDATA.REFERENCES;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE WHERE LOGGER_ID <> 0;
DELETE FROM LOGDATA.CONF_APPENDERS;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 5);
SET LOGGER_NAME = 'Test8';
CALL LOGGER.GET_LOGGER(LOGGER_NAME, LOGGER_ID_PARENT);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (LOGGER_ID_PARENT, LOGGER_NAME, 0, 5);
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
  VALUES ('More DB2 Tables-8.1', 1, NULL, '%c [%p] : %m');
SET LAST_CONF_APPENDER_ID = (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS);
CALL LOGGER.GET_LOGGER('Test8.son', LOGGER_ID);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (LOGGER_ID, 'son', LOGGER_ID_PARENT, 5);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (LOGGER_ID, LAST_CONF_APPENDER_ID);
SET EXPECTED_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS) + 1;
CALL LOGGER.INFO(LOGGER_ID, 'Message test');
SET ACTUAL_QTY = (SELECT COUNT(0) FROM LOGDATA.LOGS);
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES 
   (GENERATE_UNIQUE(), 2, 'Different qty, expected ' || COALESCE(EXPECTED_QTY, -1) || ' actual ' || COALESCE(ACTUAL_QTY,-1));
END IF;
DELETE FROM LOGDATA.REFERENCES WHERE LOGGER_ID = LOGGER_ID;
DELETE FROM LOGDATA.CONF_LOGGERS WHERE LOGGER_ID = LOGGER_ID;
DELETE FROM LOGDATA.CONF_APPENDERS WHERE REF_ID = LAST_CONF_APPENDER_ID;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 3);
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN)
  VALUES ('DB2 Tables', 1, NULL, '[%p] %c - %m');
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, (SELECT MAX(REF_ID) FROM LOGDATA.CONF_APPENDERS));
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE LIKE '%INFO%' 
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsReferences: Cleaning environment');
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsReferences: Finished succesfully');
COMMIT;

END @

