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

SET CURRENT SCHEMA LOGGER_1RC @

/**
 * Appender implementation that uses a global temporary table.
 *
 * Version: 2014-04-25 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET PATH = SYSPROC, SYSIBMADM, SYSFUN, LOGGER_1RC @

-- Tablespace for temporary logs (data).
CREATE USER TEMPORARY TABLESPACE TMP_LOG_DATA
  PAGESIZE 8 K
  EXTENTSIZE 64
  PREFETCHSIZE AUTOMATIC
  BUFFERPOOL LOG_BP @

COMMENT ON TABLESPACE TMP_LOG_DATA IS 'Logs in temporary tables' @

-- Temporary table for logs.
CREATE GLOBAL TEMPORARY TABLE LOGDATA.TEMP_LOGS
  AS (
  SELECT TIMESTAMP(CURRENT TIMESTAMP) AS DATE, LEVEL_ID, LOGGER_ID, MESSAGE
  FROM LOGDATA.LOGS) WITH NO DATA
  ON COMMIT PRESERVE ROWS
  NOT LOGGED ON ROLLBACK PRESERVE ROWS
  IN TMP_LOG_DATA @

/**
 * Writes the given message in a temporary table. If the table does not exist
 * it will create it. This is a pure SQL implementation, without any external
 * call.
 *
 * IN LOGGER_ID
 *   Identification of the associated logger.
 * IN LEVEL_ID
 *   Identification of the associates level.
 * IN MESSAGE
 *   Descriptive message to write in the log table.
 * IN CONFIGURATION
 *   Any particular configuration for the appender.
 */
ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG_CGTT (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  )
  LANGUAGE SQL
  SPECIFIC P_LOG_CGTT
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
 P_LOG_CGTT: BEGIN
  INSERT INTO LOGDATA.TEMP_LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES
    (GENERATE_UNIQUE(), LEVEL_ID, LOGGER_ID, MESSAGE);
 END P_LOG_CGTT @

-- Register the new appender in the configuration.
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES (3, 'CGTT') @

INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, CONFIGURATION,
  PATTERN, LEVEL_ID) VALUES (6, 'Temp table', 3, NULL, '[%p] %c -%T%m', NULL) @

INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID) VALUES (0, 6) @

