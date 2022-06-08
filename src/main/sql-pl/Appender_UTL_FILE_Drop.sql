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

SET CURRENT SCHEMA LOGGER_1 @

/**
 * Drops the appender implementation that writes the message to a file.
 *
 * Version: 2022-06-08 v1
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

DELETE FROM LOGDATA.REFERENCES
  WHERE APPENDER_REF_ID = 2 @

DELETE FROM LOGDATA.CONF_APPENDERS
  WHERE REF_ID = 2 @

DELETE FROM LOGDATA.APPENDERS
  WHERE APPENDER_ID = 2 @

ALTER MODULE LOGGER DROP
  SPECIFIC PROCEDURE P_LOG_UTL_FILE @

ALTER MODULE LOGGER DROP
  VARIABLE UTL_FILE_HANDLER @

