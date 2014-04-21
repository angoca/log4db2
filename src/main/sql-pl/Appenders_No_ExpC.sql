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

SET CURRENT SCHEMA LOGGER_1B @

/**
 * Implementation of the included appenders that do not necessarily work on
 * Express-C edition. Here you can find how log4db2 interacts with different
 * components to log messages.
 *
 * Version: 2014-04-02 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET PATH = SYSPROC, SYSIBMADM, SYSFUN, LOGGER_1B @

/**
 * Handle for DB2Logger.
 */
ALTER MODULE LOGGER PUBLISH
  VARIABLE UTL_FILE_HANDLER UTL_FILE.FILE_TYPE @

/**
 * Writes the provided message in a file via UTL_FILE built-in functions.
 * This appender cannot be used in Express-C edition due to restrictions of
 * the built-in modules in this edition.
 * The implementation retrieves the filename from a global variable, and
 * keeps the handler there, in order to reduce the overhead by opening and
 * closing the file for each call.
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
  PROCEDURE LOG_UTL_FILE (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR MESSAGE,
  IN CONFIGURATION ANCHOR LOGDATA.CONF_APPENDERS.CONFIGURATION
  )
  LANGUAGE SQL
  SPECIFIC P_LOG_UTL_FILE
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_LOG_UTL_FILE : BEGIN
  DECLARE DIR_ALIAS VARCHAR(128) CONSTANT 'LOG_FILE';
  DECLARE IS_OPEN BOOLEAN;
  DECLARE DIRECTORY VARCHAR(1024);
  DECLARE FILENAME VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLSTATE '58024'
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE)
    VALUES (2, 'Error accesing file: ' || COALESCE(FILENAME, 'NULL') || ' at '
    || COALESCE(DIRECTORY, 'NULL') || ' Open: ' || BOOL_TO_CHAR(IS_OPEN));

  SET IS_OPEN = UTL_FILE.IS_OPEN(UTL_FILE_HANDLER);
  IF ( IS_OPEN != TRUE ) THEN
   SET DIRECTORY = XMLCAST(
     XMLQUERY('$c/log4db2/appender/configuration/directory' PASSING CONFIGURATION AS "c")
     AS VARCHAR(128));
   SET FILENAME = XMLCAST(
     XMLQUERY('$c/log4db2/appender/configuration/filename' PASSING CONFIGURATION AS "c")
     AS VARCHAR(128));
   -- Remove any carriage return and whitespace around the value.
   SET DIRECTORY = TRIM(REPLACE(REPLACE(DIRECTORY, CHR(10), ''), CHR(13),
     ''));
   SET FILENAME = TRIM(REPLACE(REPLACE(FILENAME, CHR(10), ''), CHR(13), ''));

   -- Internal logging.
   --IF (GET_VALUE(LOG_INTERNALS) = VAL_TRUE) THEN
   -- INSERT INTO LOGS VALUES (4, -1, 'Path "' || DIRECTORY || '\' || FILENAME);
   --END IF;
   
   CALL UTL_DIR.CREATE_OR_REPLACE_DIRECTORY(DIR_ALIAS, DIRECTORY);
   SET UTL_FILE_HANDLER = UTL_FILE.FOPEN(DIR_ALIAS, FILENAME, 'a');
  END IF;
  CALL UTL_FILE.PUT_LINE(UTL_FILE_HANDLER, MESSAGE);
  CALL UTL_FILE.FFLUSH(UTL_FILE_HANDLER);
 END P_LOG_UTL_FILE @

