--#SET TERMINATOR @

/*
Copyright (c) 2012 - 2022, Andres Gomez Casanova (AngocA)
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
 * Appender implementation that prints in the current standard output of the
 * session. It needs the serverouput active:
 *   SET SERVEROUTPUT ON
 * The buffer can be easily filled if a log of messages are generated.
 *
 * Version: 2022-06-07 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET PATH = SYSPROC, SYSIBMADM, SYSFUN, LOGGER_1RC @

/**
 * Writes the given message in the standard output.
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
  PROCEDURE LOG_STDOUT (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LVL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  )
  LANGUAGE SQL
  SPECIFIC P_LOG_STDOUT
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
 P_LOG_STDOUT: BEGIN
  DECLARE LEVEL_NAME ANCHOR LOGDATA.LEVELS.NAME;
  DECLARE LOGGER_NAME ANCHOR COMPLETE_LOGGER_NAME;

  SET LEVEL_NAME = (SELECT NAME FROM LOGDATA.LEVELS WHERE LEVEL_ID = LVL_ID);
  SET LOGGER_NAME = GET_LOGGER_NAME(LOGGER_ID);

  CALL DBMS_OUTPUT.PUT_LINE(CURRENT TIMESTAMP || ' - ' || MESSAGE);
 END P_LOG_STDOUT @

-- Register the new appender in the configuration.
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES (4, 'STDOUT') @

INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, CONFIGURATION,
  PATTERN, LEVEL_ID) VALUES (6, 'Temp table', 4, NULL, '[%p] %c -%T%m', NULL) @

INSERT INTO LOGDATA.REFERENCES (LOGGER_ID, APPENDER_REF_ID) VALUES (0, 6) @

