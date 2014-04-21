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

SET CURRENT SCHEMA LOGGER_1B;

/**
 * These are the routines for the administration of the log4db2 utility.
 * They are defined in a different module in order to provide a security
 * mechanism that separates the configuration from the usage. A person who
 * writes in the logs is not the same person that configures the utility.
 *
 * Version: 2012-10-15 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

-- Module for the adminsitration for the logger utility.
CREATE OR REPLACE MODULE LOGADMIN;

COMMENT ON MODULE LOGADMIN IS 'Admin routines for the log4db2 utility';

CREATE OR REPLACE PUBLIC ALIAS LOGADMIN FOR MODULE LOGADMIN;

COMMENT ON PUBLIC ALIAS LOGADMIN FOR MODULE IS 'Administrative routines for log4db2';

-- Module version.
ALTER MODULE LOGADMIN PUBLISH
  VARIABLE VERSION VARCHAR(32) CONSTANT '2014-04-21 1-RC';

-- Deletes a value in the cache. Useful for tests.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE DELETE_LOGGER_CACHE (
  IN LOGGER ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  );

-- Shows the current configuration.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE SHOW_CONF (
  );

-- Shows the content of the cache. Useful for debuging.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE SHOW_CACHE (
  );

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

-- Procedure that shows the more recent logs written.
ALTER MODULE LOGADMIN PUBLISH
  PROCEDURE NEXT_LOGS (
  IN LENGTH SMALLINT DEFAULT 72,
  IN MIN_LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID
  );

-- Register a logger with a given level.
ALTER MODULE LOGADMIN PUBLISH
  PROCEDURE REGISTER_LOGGER (
  IN NAME ANCHOR LOGGER.COMPLETE_LOGGER_NAME,
  IN LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID
  );

-- View to retrieve the logger name with level and logger name in characters.
CREATE OR REPLACE VIEW LOG_MESSAGES 
  (DATE, LEVEL, LOGGER, MESSAGE) AS
  SELECT TIMESTAMP(L.DATE) AS DATE, LE.NAME AS LEVEL,
  LOGGER.GET_LOGGER_NAME(L.LOGGER_ID) AS LOGGER, L.MESSAGE
  FROM LOGDATA.LOGS AS L LEFT JOIN LOGDATA.LEVELS AS LE
  ON L.LEVEL_ID = LE.LEVEL_ID;

