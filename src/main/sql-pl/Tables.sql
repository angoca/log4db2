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
 * - Bufferpool
 * - Tablespaces
 * - Tables
 * - Sequences
 * - Referential integrity
 * And also some DML for the basic content for the utility to run.
 *
 * Version: 2014-02-14 1-Alpha
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

-- Buffer pool for log data.
CREATE BUFFERPOOL LOG_BP PAGESIZE 8K;

-- Tablespace for logger utility.
CREATE TABLESPACE LOGGER_SPACE
  PAGESIZE 4 K;

COMMENT ON TABLESPACE LOGGER_SPACE IS 'All configuration tables for the logger utility';

-- Tablespace for logs (data).
-- Try to change the configuration to improve the performance:
-- LARGE tablespace (more rows per page)
-- EXTENT SIZE (bigger=less preallocation)
-- PREFETCHSIZE (faster analyzes, less sync IO)
CREATE TABLESPACE LOG_DATA_SPACE
  PAGESIZE 8 K 
  EXTENTSIZE 64
  PREFETCHSIZE AUTOMATIC
  BUFFERPOOL LOG_BP;

COMMENT ON TABLESPACE LOGGER_SPACE IS 'Logs in an independent tablespace';

-- Schema for logger tables.
CREATE SCHEMA LOGDATA;

COMMENT ON SCHEMA LOGDATA IS 'Schema for table of the log4db2 utility';

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

-- Table for loggers configuration.
CREATE TABLE CONF_LOGGERS (
  LOGGER_ID SMALLINT NOT NULL,
  NAME VARCHAR(256) NOT NULL,
  PARENT_ID SMALLINT,
  LEVEL_ID SMALLINT
  ) IN LOGGER_SPACE;

ALTER TABLE CONF_LOGGERS ADD CONSTRAINT LOG_LOGGERS_PK PRIMARY KEY (LOGGER_ID);

ALTER TABLE CONF_LOGGERS ADD CONSTRAINT LOG_LOGGERS_FK_LEVELS FOREIGN KEY (LEVEL_ID) REFERENCES LEVELS (LEVEL_ID) ON DELETE CASCADE;

ALTER TABLE CONF_LOGGERS ADD CONSTRAINT LOG_LOGGERS_FK_PARENT FOREIGN KEY (PARENT_ID) REFERENCES CONF_LOGGERS (LOGGER_ID) ON DELETE CASCADE;

COMMENT ON TABLE CONF_LOGGERS IS 'Configuration table for the logger levels';

COMMENT ON CONF_LOGGERS (
  LOGGER_ID IS 'Logger identifier',
  NAME IS 'Hierarchy name to log',
  PARENT_ID IS 'Parent logger id',
  LEVEL_ID IS 'Log level to register (Optional)'
  );

-- Table for the effecetive loggers configuration.
-- This table allows to keep an id related to a specific logger across database
-- activations.
CREATE TABLE CONF_LOGGERS_EFFECTIVE
  LIKE CONF_LOGGERS IN LOGGER_SPACE;

ALTER TABLE CONF_LOGGERS_EFFECTIVE
  ADD COLUMN HIERARCHY VARCHAR(32) NOT NULL
  DEFAULT '';

ALTER TABLE CONF_LOGGERS_EFFECTIVE ALTER COLUMN LEVEL_ID SET NOT NULL;

CALL SYSPROC.ADMIN_CMD ('REORG TABLE CONF_LOGGERS_EFFECTIVE');

ALTER TABLE CONF_LOGGERS_EFFECTIVE ADD CONSTRAINT LOG_LOGGERS_EFF_PK PRIMARY KEY (LOGGER_ID);

ALTER TABLE CONF_LOGGERS_EFFECTIVE ADD CONSTRAINT LOG_LOGGERS_EFF_FK_LEVELS FOREIGN KEY (LEVEL_ID) REFERENCES LEVELS (LEVEL_ID) ON DELETE CASCADE;

ALTER TABLE CONF_LOGGERS_EFFECTIVE ADD CONSTRAINT LOG_LOGGERS_EFF_FK_PARENT FOREIGN KEY (PARENT_ID) REFERENCES CONF_LOGGERS_EFFECTIVE (LOGGER_ID) ON DELETE CASCADE;

COMMENT ON TABLE CONF_LOGGERS_EFFECTIVE IS 'Configuration table for the effective logger levels';

COMMENT ON CONF_LOGGERS_EFFECTIVE (
  LOGGER_ID IS 'Logger identifier',
  NAME IS 'Hierarchy name to log',
  PARENT_ID IS 'Parent logger id',
  LEVEL_ID IS 'Log level to register',
  HIERARCHY IS 'Comma separated numbers that represents the hierarchy'
  );

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

-- Table for the configuration about where to write the logs.
CREATE TABLE CONF_APPENDERS (
  REF_ID SMALLINT NOT NULL,
  NAME CHAR(32),
  APPENDER_ID SMALLINT NOT NULL,
  CONFIGURATION VARCHAR(256),
  PATTERN VARCHAR(256) NOT NULL
  ) IN LOGGER_SPACE;

ALTER TABLE CONF_APPENDERS ADD CONSTRAINT LOG_CONF_APPEND_PK PRIMARY KEY (REF_ID);

ALTER TABLE CONF_APPENDERS ALTER COLUMN REF_ID SET GENERATED ALWAYS AS IDENTITY (START WITH 1);

ALTER TABLE CONF_APPENDERS ADD CONSTRAINT LOG_CONF_APPEND_FK_APPEND FOREIGN KEY (APPENDER_ID) REFERENCES APPENDERS (APPENDER_ID) ON DELETE CASCADE;

COMMENT ON TABLE CONF_APPENDERS IS 'Configuration about how to write the logs';

COMMENT ON CONF_APPENDERS (
  REF_ID IS 'Id of the configuration appender',
  NAME IS 'Alias of the configuration to write the logs',
  APPENDER_ID IS 'Id of the appender where the logs will be written',
  CONFIGURATION IS 'Configuration of the appender',
  PATTERN IS 'Pattern to write the message in the log'
  );

-- Table for the loggers and appenders association.
CREATE TABLE REFERENCES (
  LOGGER_ID SMALLINT NOT NULL,
  APPENDER_REF_ID SMALLINT NOT NULL
  ) IN LOGGER_SPACE;

ALTER TABLE REFERENCES ADD CONSTRAINT LOG_REF_PK PRIMARY KEY (LOGGER_ID, APPENDER_REF_ID);

ALTER TABLE REFERENCES ADD CONSTRAINT LOG_REF_FK_CONF_LOGGERS FOREIGN KEY (LOGGER_ID) REFERENCES CONF_LOGGERS (LOGGER_ID) ON DELETE CASCADE;

ALTER TABLE REFERENCES ADD CONSTRAINT LOG_REF_FK_CONF_APPEND FOREIGN KEY (APPENDER_REF_ID) REFERENCES CONF_APPENDERS (REF_ID) ON DELETE CASCADE;

COMMENT ON TABLE REFERENCES IS 'Table that associates the loggers with the appenders';

COMMENT ON REFERENCES (
  LOGGER_ID IS 'Logger that will be written',
  APPENDER_REF_ID IS 'Appender used to write the log'
  );

-- Table for the pure SQL appender.
-- TODO make tests in order to check in a auto generated column for an id
-- does not impact the performance, and provides a better way to sort messages.
-- This ID column could be hidden to the user. The benefic is that the logs
-- could be accessed via an index, but it impacts the writes, because this
-- structure has to be maintained. 
CREATE TABLE LOGS (
  DATE CHAR(13) FOR BIT DATA NOT NULL IMPLICITLY HIDDEN,
  LEVEL_ID SMALLINT,
  LOGGER_ID SMALLINT,
  MESSAGE VARCHAR(512) NOT NULL
  ) IN LOG_DATA_SPACE;

ALTER TABLE LOGS
  PCTFREE 0
  APPEND ON
  VOLATILE CARDINALITY;

COMMENT ON TABLE LOGS IS 'Table where the logs are written';

COMMENT ON LOGS (
  DATE IS 'Date where the event was reported',
  LEVEL_ID IS 'Log level',
  LOGGER_ID IS 'Logger that generated this message',
  MESSAGE IS 'Message logged'
  );

CREATE OR REPLACE PUBLIC ALIAS LOGS FOR TABLE LOGS;

COMMENT ON PUBLIC ALIAS LOGS IS 'log4db2 logs';

/**
 * Sequence for the logger names in the tables CONF_LOGGERS and
 * CONF_LOGGERS_EFFECTIVE.
 */
CREATE OR REPLACE SEQUENCE LOGGER_ID_SEQ
  AS SMALLINT
  START WITH 0;

COMMENT ON SEQUENCE LOGGER_ID_SEQ IS 'Consecutive IDs for each logger';

-- Global configuration.
-- checkHierarchy: Checks the logger hierarchy.
-- checkLevels: Checks the levels definition.
-- defaultRootLevelId: Default ROOT logger when it is not defined (not cached)
-- internalCache: Use internal cache instead of SELECT for each time.
-- logInternals: Logs internal messages.
-- secondsToRefresh: Quantity of second before refresh the conf.
INSERT INTO CONFIGURATION (KEY, VALUE)
  VALUES ('defaultRootLevelId', '3'),
         ('internalCache', 'true'),
         ('logInternals', 'false'),
         ('secondsToRefresh', '30'),
         ('checkHierarchy', 'false'),
         ('checkLevels', 'false');

-- Levels of the logger utility.
INSERT INTO LEVELS (LEVEL_ID, NAME)
  VALUES (0, 'off'),
         (1, 'fatal'),
         (2, 'error'),
         (3, 'warn'),
         (4, 'info'),
         (5, 'debug');

-- Root logger.
INSERT INTO CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (NEXT VALUE FOR LOGGER_ID_SEQ, 'ROOT', NULL, 3);

-- Root logger in effective, it cannot be deleted after.
INSERT INTO CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID,
  LEVEL_ID, HIERARCHY)
  VALUES (PREVIOUS VALUE FOR LOGGER_ID_SEQ, 'ROOT', NULL, 3,
  CHAR(PREVIOUS VALUE FOR LOGGER_ID_SEQ));

-- Basic appenders.
INSERT INTO APPENDERS (APPENDER_ID, NAME)
  VALUES (1, 'Pure SQL PL - Tables'),
         (2, 'db2diag.log'),
         (3, 'UTL_FILE'),
         (4, 'DB2 logger'),
         (5, 'Java logger');

-- Configuration for included appender.
INSERT INTO CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION,
  PATTERN)
  VALUES ('DB2 Tables', 1, NULL, '[%p] %c - %m');

-- Configuration for appender - logger.
INSERT INTO REFERENCES (LOGGER_ID, APPENDER_REF_ID)
  VALUES (PREVIOUS VALUE FOR LOGGER_ID_SEQ, 1);

