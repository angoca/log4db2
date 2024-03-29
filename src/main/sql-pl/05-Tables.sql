--#SET TERMINATOR ;

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

SET CURRENT SCHEMA LOGDATA;

/**
 * Defines the DDL of many objects:
 * - Tables
 * - Referential integrity
 * And also some DML for the basic content for the utility to run.
 *
 * Version: 2022-06-08 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

-- Table for the global configuration of the logger utility.
CREATE TABLE CONFIGURATION (
  KEY VARCHAR(32) NOT NULL,
  VALUE VARCHAR(256) NULL
  ) IN LOGGER_SPACE;

ALTER TABLE CONFIGURATION ADD CONSTRAINT LOG_CONF_PK PRIMARY KEY (KEY);

COMMENT ON TABLE CONFIGURATION IS 'General configuration for the utility';

COMMENT ON CONFIGURATION (
  KEY IS 'Configuration Id',
  VALUE IS 'Value of the corresponding key'
  );

COMMENT ON CONSTRAINT CONFIGURATION.LOG_CONF_PK IS
  'Primary key of Configuration table';

-- Table for the logger levels.
CREATE TABLE LEVELS (
  LEVEL_ID SMALLINT NOT NULL,
  NAME CHAR(5) NOT NULL
  ) IN LOGGER_SPACE;

ALTER TABLE LEVELS ADD CONSTRAINT LOG_LEVELS_PK PRIMARY KEY (LEVEL_ID);

COMMENT ON TABLE LEVELS IS 'Possible level for the logger';

COMMENT ON LEVELS (
  LEVEL_ID IS 'Level Id',
  NAME IS 'Level name'
  );

COMMENT ON CONSTRAINT LEVELS.LOG_LEVELS_PK IS
  'Primary key of Levels table';

-- Table for loggers configuration.
CREATE TABLE CONF_LOGGERS (
  LOGGER_ID SMALLINT NOT NULL,
  NAME VARCHAR(256) NOT NULL,
  PARENT_ID SMALLINT,
  LEVEL_ID SMALLINT
  ) IN LOGGER_SPACE;

ALTER TABLE CONF_LOGGERS ADD CONSTRAINT LOG_LOGGERS_PK PRIMARY KEY (LOGGER_ID);

ALTER TABLE CONF_LOGGERS ALTER COLUMN LOGGER_ID
  SET GENERATED BY DEFAULT AS IDENTITY (START WITH 1);

ALTER TABLE CONF_LOGGERS ADD CONSTRAINT LOG_LOGGERS_FK_LEVELS
  FOREIGN KEY (LEVEL_ID) REFERENCES LEVELS (LEVEL_ID) ON DELETE CASCADE;

-- Recursive relationship.
ALTER TABLE CONF_LOGGERS ADD CONSTRAINT LOG_LOGGERS_FK_PARENT
  FOREIGN KEY (PARENT_ID) REFERENCES CONF_LOGGERS (LOGGER_ID) ON DELETE CASCADE;

COMMENT ON TABLE CONF_LOGGERS IS 'Configuration table for the logger levels';

COMMENT ON CONF_LOGGERS (
  LOGGER_ID IS 'Logger identifier',
  NAME IS 'Hierarchy name to log',
  PARENT_ID IS 'Parent logger id',
  LEVEL_ID IS 'Log level to register (Optional)'
  );

COMMENT ON CONSTRAINT CONF_LOGGERS.LOG_LOGGERS_PK IS
  'Primary key of ConfLoggers table';

COMMENT ON CONSTRAINT CONF_LOGGERS.LOG_LOGGERS_FK_LEVELS IS
  'Relationship with Levels';

COMMENT ON CONSTRAINT CONF_LOGGERS.LOG_LOGGERS_FK_PARENT IS
  'Recursive relation - parent';

-- Table for the effective loggers configuration.
-- This table allows to keep an id related to a specific logger across database
-- activations.
CREATE TABLE CONF_LOGGERS_EFFECTIVE
  LIKE CONF_LOGGERS IN LOGGER_SPACE;

ALTER TABLE CONF_LOGGERS_EFFECTIVE
  ADD COLUMN HIERARCHY VARCHAR(151) NOT NULL
  DEFAULT ' ';

ALTER TABLE CONF_LOGGERS_EFFECTIVE
  DROP COLUMN NAME;

ALTER TABLE CONF_LOGGERS_EFFECTIVE
  DROP COLUMN PARENT_ID;

ALTER TABLE CONF_LOGGERS_EFFECTIVE ALTER COLUMN LEVEL_ID SET NOT NULL;

CALL SYSPROC.ADMIN_CMD ('REORG TABLE CONF_LOGGERS_EFFECTIVE');

ALTER TABLE CONF_LOGGERS_EFFECTIVE ADD CONSTRAINT LOG_LOGGERS_EFF_PK
  PRIMARY KEY (LOGGER_ID);

ALTER TABLE CONF_LOGGERS_EFFECTIVE ADD CONSTRAINT LOG_LOGGERS_EFF_FK_LEVELS
  FOREIGN KEY (LEVEL_ID) REFERENCES LEVELS (LEVEL_ID) ON DELETE CASCADE;

ALTER TABLE CONF_LOGGERS_EFFECTIVE ADD CONSTRAINT LOG_LOGGERS_EFF_FK_CNF_LOG
  FOREIGN KEY (LOGGER_ID) REFERENCES CONF_LOGGERS (LOGGER_ID) ON DELETE CASCADE;

COMMENT ON TABLE CONF_LOGGERS_EFFECTIVE IS
  'Configuration table for the effective logger levels';

COMMENT ON CONF_LOGGERS_EFFECTIVE (
  LOGGER_ID IS 'Logger identifier',
  LEVEL_ID IS 'Log level to register',
  HIERARCHY IS 'Comma separated numbers that represents the hierarchy'
  );

COMMENT ON CONSTRAINT CONF_LOGGERS_EFFECTIVE.LOG_LOGGERS_EFF_PK IS
  'Primary key of ConfLoggersEffective table';

COMMENT ON CONSTRAINT CONF_LOGGERS_EFFECTIVE.LOG_LOGGERS_EFF_FK_LEVELS IS
  'Relationship with Levels';

COMMENT ON CONSTRAINT CONF_LOGGERS_EFFECTIVE.LOG_LOGGERS_EFF_FK_CNF_LOG IS
  'Relationship with ConfLoggers';

-- Table for the appenders.
CREATE TABLE APPENDERS (
  APPENDER_ID SMALLINT NOT NULL,
  NAME VARCHAR(256) NOT NULL
  ) IN LOGGER_SPACE;

ALTER TABLE APPENDERS ADD CONSTRAINT LOG_APPEND_PK PRIMARY KEY (APPENDER_ID);

COMMENT ON TABLE APPENDERS IS 'Possible appenders';

COMMENT ON APPENDERS (
  APPENDER_ID IS 'Id of the appender',
  NAME IS 'Name of the appender'
  );

COMMENT ON CONSTRAINT APPENDERS.LOG_APPEND_PK IS
  'Primary key of Appenders table';

-- Table for the configuration about where to write the logs.
CREATE TABLE CONF_APPENDERS (
  REF_ID SMALLINT NOT NULL,
  NAME CHAR(32),
  APPENDER_ID SMALLINT NOT NULL,
  CONFIGURATION XML INLINE LENGTH 1000,
  PATTERN VARCHAR(256),
  LEVEL_ID SMALLINT
  ) IN LOGGER_SPACE;

ALTER TABLE CONF_APPENDERS ADD CONSTRAINT LOG_CONF_APPEND_PK
  PRIMARY KEY (REF_ID);

ALTER TABLE CONF_APPENDERS ALTER COLUMN REF_ID
  SET GENERATED BY DEFAULT AS IDENTITY (START WITH 0);

ALTER TABLE CONF_APPENDERS ADD CONSTRAINT LOG_CONF_APPEND_FK_APPEND
  FOREIGN KEY (APPENDER_ID) REFERENCES APPENDERS (APPENDER_ID)
  ON DELETE CASCADE;

ALTER TABLE CONF_APPENDERS ADD CONSTRAINT LOG_CONF_APPEND_FK_LEVELS
  FOREIGN KEY (LEVEL_ID) REFERENCES LEVELS (LEVEL_ID) ON DELETE CASCADE;

COMMENT ON TABLE CONF_APPENDERS IS 'Configuration about how to write the logs';

COMMENT ON CONF_APPENDERS (
  REF_ID IS 'Id of the configuration appender',
  NAME IS 'Alias of the configuration to write the logs',
  APPENDER_ID IS 'Id of the appender where the logs will be written',
  CONFIGURATION IS 'Configuration of the appender',
  PATTERN IS 'Pattern to write the message in the log',
  LEVEL_ID IS 'Minimum level to log'
  );

COMMENT ON CONSTRAINT CONF_APPENDERS.LOG_CONF_APPEND_PK IS
  'Primary key of ConfAppenders table';

COMMENT ON CONSTRAINT CONF_APPENDERS.LOG_CONF_APPEND_FK_APPEND IS
  'Relationship with Appenders';

COMMENT ON CONSTRAINT CONF_APPENDERS.LOG_CONF_APPEND_FK_LEVELS IS
  'Relationship with Levels';

-- Table for the loggers and appenders association.
CREATE TABLE REFERENCES (
  LOGGER_ID SMALLINT NOT NULL,
  APPENDER_REF_ID SMALLINT NOT NULL
  ) IN LOGGER_SPACE;

ALTER TABLE REFERENCES ADD CONSTRAINT LOG_REF_PK
  PRIMARY KEY (LOGGER_ID, APPENDER_REF_ID);

ALTER TABLE REFERENCES ADD CONSTRAINT LOG_REF_FK_CONF_LOGGERS
  FOREIGN KEY (LOGGER_ID) REFERENCES CONF_LOGGERS (LOGGER_ID) ON DELETE CASCADE;

ALTER TABLE REFERENCES ADD CONSTRAINT LOG_REF_FK_CONF_APPEND
  FOREIGN KEY (APPENDER_REF_ID) REFERENCES CONF_APPENDERS (REF_ID)
  ON DELETE CASCADE;

COMMENT ON TABLE REFERENCES IS
  'Table that associates the loggers with the appenders';

COMMENT ON REFERENCES (
  LOGGER_ID IS 'Logger that will be written',
  APPENDER_REF_ID IS 'Appender used to write the log'
  );

COMMENT ON CONSTRAINT REFERENCES.LOG_REF_PK IS
  'Primary key of References table';

COMMENT ON CONSTRAINT REFERENCES.LOG_REF_FK_CONF_LOGGERS IS
  'Relationship with ConfLoggers';

COMMENT ON CONSTRAINT REFERENCES.LOG_REF_FK_CONF_APPEND IS
  'Relationship with ConfAppenders';

-- Table for the license.
CREATE TABLE LICENSE (
  NUMBER SMALLINT,
  LINE VARCHAR(80)
  );

COMMENT ON TABLE LICENSE IS 'License of log4db2';

COMMENT ON LICENSE (
  NUMBER IS 'Number of the line',
  LINE IS 'Content of the license'
  );

-- Levels of the logger utility.
INSERT INTO LEVELS (LEVEL_ID, NAME)
  VALUES (0, 'off');

-- Root logger.
INSERT INTO CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);

-- Root logger in effective, it cannot be deleted after.
INSERT INTO CONF_LOGGERS_EFFECTIVE (LOGGER_ID, LEVEL_ID, HIERARCHY)
  VALUES (0, 0, '0');

INSERT INTO LICENSE (NUMBER, LINE) VALUES
  (1, ' log4db2: A logging utility like log4j for IBM DB2 SQL PL.'),
  (2, ' Copyright (c) 2012 - 202, Andres Gomez Casanova (@AngocA)'),
  (3, ' All rights reserved.'),
  (4, ' '),
  (5, ' Redistribution and use in source and binary forms, with or without'),
  (6, ' modification, are permitted provided that the following conditions are met:'),
  (7, ' '),
  (8, ' 1. Redistributions of source code must retain the above copyright notice, this'),
  (9, '    list of conditions and the following disclaimer.'),
  (10, ' 2. Redistributions in binary form must reproduce the above copyright notice,'),
  (11, '    this list of conditions and the following disclaimer in the documentation'),
  (12, '    and/or other materials provided with the distribution.'),
  (13, ' '),
  (14, 'THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND'),
  (15, 'ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED'),
  (16, 'WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE'),
  (17, 'DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE'),
  (18, 'FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL'),
  (19, 'DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR'),
  (20, 'SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER'),
  (21, 'CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,'),
  (22, 'OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE'),
  (23, 'OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'),
  (24, ''),
  (25, ' Andres Gomez Casanova <angocaATyahooDOTcom>');

