--#SET TERMINATOR ;
SET CURRENT SCHEMA LOGGER_1A;

/**
 * These are the routines for the administration of the log4db2 utility.
 * They are defined in a different module in order to provide a security
 * mechanism that separates the configuration from the usage. A person who
 * writes in the logs is not the same person that configures the utility.
 *
 * Version: 2012-10-15 1-Alpha
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

-- Module for the adminsitration for the logger utility.
CREATE OR REPLACE MODULE LOGADMIN;

COMMENT ON MODULE LOGADMIN IS 'Admin routines for the log4db2 utility';

CREATE OR REPLACE PUBLIC ALIAS LOGADMIN FOR MODULE LOGADMIN;

-- Module version.
ALTER MODULE LOGADMIN PUBLISH
  VARIABLE VERSION VARCHAR(32) CONSTANT '2012-10-14 1-Alpha';

-- Procedure that shows the used loggers (Table CONF_LOGGERS_EFFECTIVE).
ALTER MODULE LOGADMIN PUBLISH
  PROCEDURE SHOW_LOGGERS (
  );

-- Procedure that shows the logs written.
ALTER MODULE LOGADMIN PUBLISH
  PROCEDURE LOGS (
  IN LENGTH SMALLINT DEFAULT 72,
  IN QTY SMALLINT DEFAULT 100,
  IN MIN_LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID
  );

-- Changes the descendancy of a logger.
ALTER MODULE LOGADMIN PUBLISH
  PROCEDURE MODIFY_DESCENDANTS (
  IN PARENT ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID
  );

-- Retrieves the level of the closer ascendency or default value.
ALTER MODULE LOGADMIN PUBLISH
  FUNCTION GET_DEFINED_PARENT_LOGGER (
  IN SON_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  ) RETURNS ANCHOR LOGDATA.LEVELS.LEVEL_ID;

-- View to retrieve the logger name with level and logger name in characters.
CREATE OR REPLACE VIEW LOG_MESSAGES 
  (DATE, LEVEL, LOGGER, MESSAGE) AS
  SELECT TIMESTAMP(L.DATE) AS DATE, LE.NAME AS LEVEL,
  LOGGER.GET_LOGGER_NAME(L.LOGGER_ID) AS LOGGER, L.MESSAGE
  FROM LOGDATA.LOGS AS L LEFT JOIN LOGDATA.LEVELS AS LE
  ON L.LEVEL_ID = LE.LEVEL_ID;