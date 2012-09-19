-- Drops all objects.
DROP MODULE LOGGER.LOGGER;

DROP TABLE logger.logs;
DROP TABLE logger.references;
DROP TABLE logger.conf_appenders;
DROP TABLE logger.appenders;
DROP TABLE logger.conf_loggers_effective;
DROP TABLE logger.conf_loggers;
DROP TABLE logger.levels;
DROP TABLE logger.configuration;
DROP SCHEMA logger RESTRICT;
DROP TABLESPACE logger_space;

-- Tablespace for logger utility.
CREATE TABLESPACE logger_space PAGESIZE 4 K;
COMMENT ON TABLESPACE logger_space IS 'All objects for the logger utility';

-- Schema for logger utility's objects.
CREATE SCHEMA logger;
COMMENT ON SCHEMA logger IS 'Schema for log4db2 utility';

-- Table for the global configuration of the logger utility.
CREATE TABLE logger.configuration (
  key VARCHAR(32) NOT NULL,
  value VARCHAR(256) NULL
) IN logger_space;
ALTER TABLE logger.configuration ADD CONSTRAINT log_conf_pk PRIMARY KEY (key);
COMMENT ON TABLE logger.configuration IS 'General configuration for the utility';
COMMENT ON logger.configuration (
  key IS 'Configuration Id',
  value IS 'Value of the corresponding key'
);

-- Table for the logger levels.
CREATE TABLE logger.levels (
  level_id SMALLINT NOT NULL,
  name CHAR(5) NOT NULL
) IN logger_space;
ALTER TABLE logger.levels ADD CONSTRAINT log_levels_pk PRIMARY KEY (level_id);
COMMENT ON TABLE logger.levels IS 'Possible level for the logger';
COMMENT ON logger.levels (
  level_id IS 'Level Id',
  name IS 'Level name'
);

-- Table for loggers configuration.
CREATE TABLE logger.conf_loggers (
  logger_id SMALLINT NOT NULL,
  name VARCHAR(256) NOT NULL,
  parent_id SMALLINT,
  level_id SMALLINT
) IN logger_space;
ALTER TABLE logger.conf_loggers ADD CONSTRAINT log_loggers_pk PRIMARY KEY (logger_id);
ALTER TABLE logger.conf_loggers ADD CONSTRAINT log_loggers_fk_levels FOREIGN KEY (level_id) REFERENCES logger.levels (level_id) ON DELETE CASCADE;
COMMENT ON TABLE logger.conf_loggers IS 'Configuration table for the logger levels';
COMMENT ON logger.conf_loggers (
  logger_Id IS 'Logger identifier',
  name IS 'Hierarchy name to log',
  parent_id IS 'Parent logger id',
  level_id IS 'Log level to register (Optional)'
);

-- Table for the effecetive loggers configuration.
CREATE TABLE logger.conf_loggers_effective
 LIKE logger.conf_loggers IN logger_space;
ALTER TABLE logger.conf_loggers_effective ALTER COLUMN level_id SET NOT NULL;
ALTER TABLE logger.conf_loggers_effective ALTER COLUMN logger_id set GENERATED ALWAYS AS IDENTITY (START WITH 0);
CALL SYSPROC.ADMIN_CMD ('REORG TABLE logger.conf_loggers_effective');
ALTER TABLE logger.conf_loggers_effective ADD CONSTRAINT log_loggers_eff_pk PRIMARY KEY (logger_id);
ALTER TABLE logger.conf_loggers_effective ADD CONSTRAINT log_loggers_eff_fk_levels FOREIGN KEY (level_id) REFERENCES logger.levels (level_id) ON DELETE CASCADE;
COMMENT ON TABLE logger.conf_loggers_effective IS 'Configuration table for the effective logger levels';
COMMENT ON logger.conf_loggers_effective (
  logger_Id IS 'Logger identifier',
  name IS 'Hierarchy name to log',
  parent_id IS 'Parent logger id',
  level_id IS 'Log level to register'
);

-- Table for the appenders.
CREATE TABLE logger.appenders (
    appender_id SMALLINT NOT NULL,
    name VARCHAR(256) NOT NULL
) IN logger_space;
ALTER TABLE logger.appenders ADD CONSTRAINT log_append_pk PRIMARY KEY (appender_id);
COMMENT ON TABLE logger.appenders IS 'Possible appenders';
COMMENT ON logger.appenders (
  appender_id IS 'Id of the appender',
  name IS 'Name of the appender'
);

-- Table for the configuration about where to write the logs.
CREATE TABLE logger.conf_appenders (
  ref_id SMALLINT NOT NULL,
  name CHAR(16),
  appender_id SMALLINT NOT NULL,
  configuration VARCHAR(256)
  --pattern VARCHAR(256)
) IN logger_space;
ALTER TABLE logger.conf_appenders ADD CONSTRAINT log_conf_append_pk PRIMARY KEY (ref_id);
ALTER TABLE logger.conf_appenders ADD CONSTRAINT log_conf_append_fk_append FOREIGN KEY (appender_id) REFERENCES logger.appenders (appender_id) ON DELETE CASCADE;
COMMENT ON TABLE logger.conf_appenders IS 'Configuration about how to write the logs';
COMMENT ON logger.conf_appenders (
  ref_id IS 'Id of the configuration appender',
  name IS 'Alias of the configuration to write the logs',
  appender_id IS 'Id of the appender where the logs will be written',
  configuration IS 'Configuration of the appender'
  --pattern IS 'Pattern to write the message in the log'
);

-- Table for the loggers and appenders association.
CREATE TABLE logger.references (
  logger_id SMALLINT NOT NULL,
  appender_ref_id SMALLINT NOT NULL
) IN logger_space;
ALTER TABLE logger.references ADD CONSTRAINT log_ref_pk PRIMARY KEY (logger_id);
ALTER TABLE logger.references ADD CONSTRAINT log_ref_fk_conf_loggers FOREIGN KEY (logger_id) REFERENCES logger.conf_loggers (logger_id) ON DELETE CASCADE;
ALTER TABLE logger.references ADD CONSTRAINT log_ref_fk_conf_append FOREIGN KEY (appender_ref_id) REFERENCES logger.conf_appenders (ref_id) ON DELETE CASCADE;
COMMENT ON TABLE logger.references IS 'Table that associates the loggers with the appenders';
COMMENT ON logger.references (
  logger_id IS 'Logger that will be written',
  appender_ref_id IS 'Appender used to write the log'
);

-- Table for the pure SQL appender.
CREATE TABLE logger.logs (
    date TIMESTAMP NOT NULL,
    level_id SMALLINT NOT NULL,
    logger_id SMALLINT NOT NULL,
    thread VARCHAR(32) NOT NULL,
    message VARCHAR(256) NOT NULL
) IN logger_space;
COMMENT ON TABLE logger.logs IS 'Table where the logs are written';
COMMENT ON logger.logs (
  date IS 'Date where the event was reported',
  level_id IS 'Log level',
  logger_id IS 'Logger that generated this message',
  thread IS 'Process or agent name that called the logger',
  message IS 'Message logged'
);

-- Global configuration.
INSERT INTO logger.configuration (key, value) VALUES
('checkHierarchy', 'false'),
('checkLevels', 'false');

-- Levels of the logger utility.
INSERT INTO logger.levels (level_id, name) VALUES
(0, 'off'),
(1, 'fatal'),
(2, 'error'),
(3, 'warn'),
(4, 'info'),
(5, 'debug');

-- Root logger.
INSERT INTO logger.conf_loggers (logger_id, name, parent_id, level_id) VALUES
(0, 'ROOT', NULL, 3);
-- TODO remove this, and create it with a trigger
INSERT INTO logger.conf_loggers_effective (name, parent_id, level_id) VALUES
('ROOT', NULL, 3);

-- Basic appender.
INSERT INTO logger.appenders (appender_id, name) VALUES
(0, 'Pure SQL - Tables'),
(1, 'db2diag.log'),
(2, 'UTL_FILE'),
(3, 'DB2 logger'),
(4, 'slf4j');

-- Module for all code for the logger utility.
CREATE OR REPLACE MODULE LOGGER;

-- Public functions and procedures.
-- Procedure to write logs.
ALTER MODULE LOGGER PUBLISH
 PROCEDURE LOG (
  IN LOGGERID ANCHOR LOGGER.CONF_LOGGERS.LOGGER_ID,
  IN LEVELID ANCHOR LOGGER.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGGER.LOGS.MESSAGE
 );

-- Function to register the logger.
ALTER MODULE LOGGER PUBLISH
 FUNCTION GET_LOGGER (
  IN NAME VARCHAR(256)
 ) RETURNS ANCHOR LOGGER.CONF_LOGGERS.LOGGER_ID;

-- Array to store the hierarhy of a logger.
--ALTER MODULE LOGGER ADD
-- TYPE HIERARCHY_ARRAY AS VARCHAR(32) ARRAY[16];