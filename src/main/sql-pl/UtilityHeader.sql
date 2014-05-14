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

SET CURRENT SCHEMA LOGGER_1RC;

/**
 * Defines the headers of the public procedures and functions.
 *
 * Version: 2014-02-14 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

-- Schema for logger utility's objects.
CREATE SCHEMA LOGGER_1RC;

COMMENT ON SCHEMA LOGGER_1RC IS 'Schema for objects of the log4db2 utility';

-- Module for all code for the logger utility.
CREATE OR REPLACE MODULE LOGGER;

COMMENT ON MODULE LOGGER IS 'Objects for the log4db2 utility';

CREATE OR REPLACE PUBLIC ALIAS LOGGER FOR MODULE LOGGER;

COMMENT ON PUBLIC ALIAS LOGGER FOR MODULE IS 'Objects of log4db2';

-- Module version.
ALTER MODULE LOGGER PUBLISH
  VARIABLE VERSION VARCHAR(32) CONSTANT '2014-04-21 1-RC';

-- Constant for logInternals
ALTER MODULE LOGGER PUBLISH
  VARIABLE LOG_INTERNALS ANCHOR LOGDATA.CONFIGURATION.KEY CONSTANT 'logInternals';

-- Constant for true.
ALTER MODULE LOGGER PUBLISH
  VARIABLE VAL_TRUE ANCHOR LOGDATA.CONFIGURATION.VALUE CONSTANT 'true';

-- Complete logger name.
ALTER MODULE LOGGER PUBLISH
  VARIABLE COMPLETE_LOGGER_NAME VARCHAR(256) CONSTANT NULL;

-- Data type for message.
ALTER MODULE LOGGER PUBLISH
  VARIABLE MESSAGE ANCHOR LOGDATA.LOGS.MESSAGE CONSTANT NULL;

-- Data type for message.
ALTER MODULE LOGGER PUBLISH
  VARIABLE LOCK_MODIFY_DESCENDANTS ANCHOR LOGDATA.CONFIGURATION.VALUE;

-- Public functions and procedures.
-- Writes a log.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR MESSAGE
  );

-- Write a log in debug mode.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE DEBUG (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN MESSAGE ANCHOR MESSAGE
  );

-- Writes a log in info mode.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE INFO (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN MESSAGE ANCHOR MESSAGE
  );

-- Writes a log in warn mode.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE WARN (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN MESSAGE ANCHOR MESSAGE
  );

-- Writes a log in error mode.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE ERROR (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN MESSAGE ANCHOR MESSAGE
  );

-- Writes a log in fatal mode.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE FATAL (
  IN LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN MESSAGE ANCHOR MESSAGE
  );

-- Registers the logger and retreives its ID.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE GET_LOGGER (
  IN NAME ANCHOR COMPLETE_LOGGER_NAME,
  OUT LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  );

-- Procedure to retrieve the complete logger name.
ALTER MODULE LOGGER PUBLISH
  FUNCTION GET_LOGGER_NAME (
  IN LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  ) RETURNS ANCHOR COMPLETE_LOGGER_NAME;

-- Activates the cache.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE ACTIVATE_CACHE (
  );

-- Deactivates the cache.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE DEACTIVATE_CACHE (
  );

-- Cleans up the configuration. Useful for tests.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE UNLOAD_CONF (
  );

-- Refreshes the configuration.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE REFRESH_CACHE (
  );

-- Returns the value of a configuration key.
ALTER MODULE LOGGER PUBLISH
  FUNCTION GET_VALUE (
  IN GIVEN_KEY ANCHOR LOGDATA.CONFIGURATION.KEY
  ) RETURNS ANCHOR LOGDATA.CONFIGURATION.VALUE;

-- Changes the descendancy of a logger.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE MODIFY_DESCENDANTS (
  IN PARENT ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID
  );

-- Retrieves the level of the closer ascendency or default value.
ALTER MODULE LOGGER PUBLISH
  FUNCTION GET_DEFINED_PARENT_LOGGER (
  IN SON_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  ) RETURNS ANCHOR LOGDATA.LEVELS.LEVEL_ID;

