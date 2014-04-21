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
 * Drops all seauences, alias, tables, schemas, tablespaces and bufferpools.
 *
 * Version: 2014-02-14 1-Beta
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

DROP PUBLIC ALIAS LOGS;

DROP TABLE LOGS;

DROP TABLE REFERENCES;

DROP TABLE CONF_APPENDERS;

DROP TABLE APPENDERS;

DROP TABLE CONF_LOGGERS_EFFECTIVE;

DROP TABLE CONF_LOGGERS;

DROP TABLE LEVELS;

DROP TABLE CONFIGURATION;

DROP SCHEMA LOGDATA RESTRICT;

DROP TABLESPACE LOG_DATA_SPACE;

DROP TABLESPACE LOGGER_SPACE;

DROP BUFFERPOOL LOG_BP;

DROP BUFFERPOOL LOG_CONF_BP;

! echo "If any error appeared during uninstall, please execute:";
! echo "db2 DROP TABLE ERRORSCHEMA.ERRORTABLE";
! echo "db2 \"CALL SYSPROC.ADMIN_DROP_SCHEMA('LOGGER_1B', NULL, 'ERRORSCHEMA', 'ERRORTABLE')\"";
! echo "db2 \"CALL SYSPROC.ADMIN_DROP_SCHEMA('LOGDATA', NULL, 'ERRORSCHEMA', 'ERRORTABLE')\"";
! echo "db2 \"SELECT * FROM ERRORSCHEMA.ERRORTABLE\"";
! echo "db2 \"SELECT VARCHAR('db2 DROP PACKAGE LOGGER_1B.' || TRIM(NAME) || ';db2 DROP SCHEMA LOGGER_1B RESTRICT', 128) FROM SYSIBM.SYSPLAN WHERE CREATOR LIKE 'LOG%'\"";

