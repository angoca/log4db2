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
 * Tests for the dynamic appenders.
 *
 * Version: 2014-04-21 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET CURRENT SCHEMA LOGGER_1B @

ALTER MODULE LOGGER PUBLISH 
  PROCEDURE LOG_PUBLISHED (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGGER.MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  ) SPECIFIC P_TEST_LOG_PUBLISHED@

ALTER MODULE LOGGER PUBLISH 
  PROCEDURE LOG_TABLES (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGGER.MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  )
  SPECIFIC P_TEST_LOG_TABLES_LONG
 BEGIN
  CALL LOG_TABLES(LOGGER_ID, LEVEL_ID, MESSAGE);
 END @

ALTER MODULE LOGGER PUBLISH 
  PROCEDURE LOG_SIMILIAR (
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION,
  IN MESSAGE ANCHOR LOGGER.MESSAGE,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  )
  SPECIFIC P_TEST_LOG_SIMILAR
 BEGIN
 END @

ALTER MODULE LOGGER PUBLISH 
  PROCEDURE LOG_SIGNAL (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGGER.MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  )
  SPECIFIC P_TEST_LOG_SIGNAL
 BEGIN
  SIGNAL SQLSTATE VALUE 'TEST1'
    SET MESSAGE_TEXT = 'Error from LOG_SIGNAL';
 END @

ALTER MODULE LOGGER PUBLISH 
  PROCEDURE LOG_RESIGNAL (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGGER.MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  )
  SPECIFIC P_TEST_LOG_RESIGNAL
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLSTATE 'TES2A'
    RESIGNAL SQLSTATE 'TES2B'
    SET MESSAGE_TEXT = 'Resignal message';
   SIGNAL SQLSTATE VALUE 'TES2A'
     SET MESSAGE_TEXT = 'Error from LOG_RESIGNAL';
  END @

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '0000';

DECLARE MESSAGE ANCHOR LOGDATA.LOGS.MESSAGE;
DECLARE EXPECTED_QTY SMALLINT;
DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
DECLARE ACTUAL_QTY SMALLINT;
DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
DECLARE PREP STATEMENT;

-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsDynamicAppenders: Preparing environment');
DELETE FROM LOGDATA.REFERENCES;
DELETE FROM LOGDATA.CONF_APPENDERS;
DELETE FROM LOGDATA.APPENDERS;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME)
  VALUES (0, 'Null'),
         (1, 'Tables');
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = 'false'
  WHERE KEY = 'logInternals';
CALL LOGGER.REFRESH_CACHE();

-- Test01: Inserts in table using dynamic appender.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test01: Inserts in table using dynamic appender');
DELETE FROM LOGDATA.CONF_APPENDERS;
DELETE FROM LOGDATA.APPENDERS
  WHERE APPENDER_ID >= 2;
SET EXPECTED_QTY = 1;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (2, 'TABLES');
INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN, LEVEL_ID) VALUES
  (1, 'test1', 2, '%m', null);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, 1);
CALL LOGGER.FATAL(0, 'Message test 1.');
SELECT COUNT(1) INTO ACTUAL_QTY
  FROM LOGS
  WHERE MESSAGE LIKE '%Message test 1.%';
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different qty');
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected ' || COALESCE(EXPECTED_QTY, -1) || ' actual ' || COALESCE(ACTUAL_QTY,-1));
END IF;
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE = 'Message test 1.'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Test02: Inserts in table using dynamic and built-in appender.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test02: Inserts in table using dynamic and built-in appender');
DELETE FROM LOGDATA.CONF_APPENDERS;
DELETE FROM LOGDATA.APPENDERS
  WHERE APPENDER_ID >= 2;
SET EXPECTED_QTY = 2;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (2, 'TABLES');
INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN, LEVEL_ID) VALUES
  (1, 'test2A', 1, '%m', null);
INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN, LEVEL_ID) VALUES
  (2, 'test2B', 2, '%m', null);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, 1);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, 2);
CALL LOGGER.FATAL(0, 'Message test 2.');
SELECT COUNT(1) INTO ACTUAL_QTY
  FROM LOGS
  WHERE MESSAGE LIKE '%Message test 2.%';
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different qty');
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected ' || COALESCE(EXPECTED_QTY, -1) || ' actual ' || COALESCE(ACTUAL_QTY,-1));
END IF;
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE = 'Message test 2.'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE = 'Message test 2.'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Test03: Inserts in table using built-in appender.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test03: Inserts in table using built-in appender');
DELETE FROM LOGDATA.CONF_APPENDERS;
DELETE FROM LOGDATA.APPENDERS
  WHERE APPENDER_ID >= 2;
SET EXPECTED_QTY = 1;
INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN, LEVEL_ID) VALUES
  (1, 'test3', 1, '%m', null);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, 1);
CALL LOGGER.FATAL(0, 'Message test 3.');
SELECT COUNT(1) INTO ACTUAL_QTY
  FROM LOGS
  WHERE MESSAGE LIKE '%Message test 3.%';
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different qty');
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected ' || COALESCE(EXPECTED_QTY, -1) || ' actual ' || COALESCE(ACTUAL_QTY,-1));
END IF;
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE = 'Message test 3.'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Test04: Tries to use an inexistant appender.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test04: Tries to use an inexistant appender');
SET MESSAGE = 'Message test 4.';
SET EXPECTED_MSG = 'Inexistant appender: test4=[FATAL] ' || MESSAGE;
DELETE FROM LOGDATA.CONF_APPENDERS;
DELETE FROM LOGDATA.APPENDERS
  WHERE APPENDER_ID >= 2;
SET EXPECTED_QTY = 1;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (4, 'INEXISTANT');
INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN, LEVEL_ID) VALUES
  (1, 'test4', 4, '[%p] %m', null);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, 1);
CALL LOGGER.FATAL(0, MESSAGE);
SELECT MESSAGE INTO ACTUAL_MSG
  FROM LOGS
  WHERE DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED_MSG <> ACTUAL_MSG) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different msg');
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected ' || COALESCE(EXPECTED_MSG, 'empty') || ' actual ' || COALESCE(ACTUAL_MSG, 'empty'));
END IF;
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE = EXPECTED_MSG
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Test05: Tries to use a published appender.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test05: Tries to use a published appender');
SET MESSAGE = 'Message test 5.';
SET EXPECTED_MSG = 'Appender not available: test5=[FATAL] ' || MESSAGE;
DELETE FROM LOGDATA.CONF_APPENDERS;
DELETE FROM LOGDATA.APPENDERS
  WHERE APPENDER_ID >= 2;
SET EXPECTED_QTY = 1;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (5, 'PUBLISHED');
INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN, LEVEL_ID) VALUES
  (1, 'test5', 5, '[%p] %m', null);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, 1);
CALL LOGGER.FATAL(0, MESSAGE);
SELECT MESSAGE INTO ACTUAL_MSG
  FROM LOGS
  WHERE DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED_MSG <> ACTUAL_MSG) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different msg');
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected ' || COALESCE(EXPECTED_MSG, 'empty') || ' actual ' || COALESCE(ACTUAL_MSG, 'empty'));
END IF;
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE = EXPECTED_MSG
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Test06: Tries to use a similar appender.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test06: Tries to use a similar appender');
SET MESSAGE = 'Message test 6.';
SET EXPECTED_MSG = 'Inexistant appender: test6=[FATAL] ' || MESSAGE;
DELETE FROM LOGDATA.CONF_APPENDERS;
DELETE FROM LOGDATA.APPENDERS
  WHERE APPENDER_ID >= 2;
SET EXPECTED_QTY = 1;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (6, 'SIMILAR');
INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN, LEVEL_ID) VALUES
  (1, 'test6', 6, '[%p] %m', null);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, 1);
CALL LOGGER.FATAL(0, MESSAGE);
SELECT MESSAGE INTO ACTUAL_MSG
  FROM LOGS
  WHERE DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED_MSG <> ACTUAL_MSG) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different msg');
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected ' || COALESCE(EXPECTED_MSG, 'empty') || ' actual ' || COALESCE(ACTUAL_MSG, 'empty'));
END IF;
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE = EXPECTED_MSG
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Test07: Tries to use an appender with signal.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test07: Tries to use an appender with signal');
SET MESSAGE = 'Message test 7.';
SET EXPECTED_MSG = 'Appender test7:-Exception SQLCode -438-SQLState TEST1=' || MESSAGE;
DELETE FROM LOGDATA.CONF_APPENDERS;
DELETE FROM LOGDATA.APPENDERS
  WHERE APPENDER_ID >= 2;
SET EXPECTED_QTY = 1;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (7, 'SIGNAL');
INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN, LEVEL_ID) VALUES
  (1, 'test7', 7, '%m', null);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, 1);
CALL LOGGER.FATAL(0, MESSAGE);
SELECT MESSAGE INTO ACTUAL_MSG
  FROM LOGS
  WHERE DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED_MSG <> ACTUAL_MSG) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different msg');
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected ' || COALESCE(EXPECTED_MSG, 'empty') || ' actual ' || COALESCE(ACTUAL_MSG, 'empty'));
END IF;
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE = EXPECTED_MSG
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Test08: Tries to use an appender with resignal.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test08: Tries to use an appender with resignal');
SET MESSAGE = 'Message test 8.';
SET EXPECTED_MSG = 'Appender test8:-Exception SQLCode -438-SQLState TES2B=' || MESSAGE;
DELETE FROM LOGDATA.CONF_APPENDERS;
DELETE FROM LOGDATA.APPENDERS
  WHERE APPENDER_ID >= 2;
SET EXPECTED_QTY = 1;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (8, 'RESIGNAL');
INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN, LEVEL_ID) VALUES
  (1, 'test8', 8, '[%p] %m', null);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, 1);
CALL LOGGER.FATAL(0, MESSAGE);
SELECT MESSAGE INTO ACTUAL_MSG
  FROM LOGS
  WHERE DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED_MSG <> ACTUAL_MSG) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different msg');
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected ' || COALESCE(EXPECTED_MSG, 'empty') );--|| ' actual ' || COALESCE(ACTUAL_MSG, 'empty'));
END IF;
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE = EXPECTED_MSG
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Test09: Inserts in table using dynamic appender with pattern.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test09: Inserts in table using dynamic appender with pattern');
SET MESSAGE = 'Message test 9.';
SET EXPECTED_MSG = '[FATAL] ' || MESSAGE;
DELETE FROM LOGDATA.CONF_APPENDERS;
DELETE FROM LOGDATA.APPENDERS
  WHERE APPENDER_ID >= 2;
SET EXPECTED_QTY = 1;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (2, 'TABLES');
INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN, LEVEL_ID) VALUES
  (1, 'test1', 2, '[%p] %m', null);
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, 1);
CALL LOGGER.FATAL(0, 'Message test 1.');
SELECT COUNT(1) INTO ACTUAL_QTY
  FROM LOGS
  WHERE MESSAGE LIKE '%Message test 1.%';
IF (EXPECTED_QTY <> ACTUAL_QTY) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different qty');
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected ' || COALESCE(EXPECTED_QTY, -1) || ' actual ' || COALESCE(ACTUAL_QTY,-1));
END IF;
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE = '[FATAL] Message test 1.'
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
COMMIT;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsDynamicAppenders: Cleaning environment');
DELETE FROM LOGDATA.REFERENCES;
DELETE FROM LOGDATA.CONF_APPENDERS;
DELETE FROM LOGDATA.APPENDERS;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME)
  VALUES (0, 'Null'),
         (1, 'Tables');
INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, CONFIGURATION,
  PATTERN)
  VALUES (1, 'Tables', 1, NULL, '[%p] %c - %m');
-- Configuration for appender - logger.
INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (0, 1);
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE)
  VALUES ('autonomousLogging', 'true'),
         ('defaultRootLevelId', '3'),
         ('internalCache', 'true'),
         ('logInternals', 'false'),
         ('secondsToRefresh', '30');
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsDynamicAppenders: Finished succesfully');

END @

ALTER MODULE LOGGER DROP
  SPECIFIC PROCEDURE P_TEST_LOG_TABLES_LONG @

ALTER MODULE LOGGER DROP
  SPECIFIC PROCEDURE P_TEST_LOG_SIMILAR @

ALTER MODULE LOGGER DROP
  SPECIFIC PROCEDURE P_TEST_LOG_SIGNAL @

ALTER MODULE LOGGER DROP
  SPECIFIC PROCEDURE P_TEST_LOG_RESIGNAL @

ALTER MODULE LOGGER DROP 
  SPECIFIC PROCEDURE P_TEST_LOG_PUBLISHED @

