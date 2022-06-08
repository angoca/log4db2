--#SET TERMINATOR ;

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

/**
 * DDL to activate the TimeTravel features in some tables.
 *
 * Version: 2022-06-03 v1
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

-- Logs (Pure SQL appender)
-- Logs can be modified to show a different behaviour, and this
-- table is create to detect that.

ALTER TABLE LOGDATA.LOGS
  ADD COLUMN SYS_START TIMESTAMP(12) NOT NULL GENERATED ALWAYS
  AS ROW BEGIN IMPLICITLY HIDDEN;

ALTER TABLE LOGDATA.LOGS
  ADD COLUMN SYS_END TIMESTAMP(12) NOT NULL GENERATED ALWAYS
  AS ROW END IMPLICITLY HIDDEN;

ALTER TABLE LOGDATA.LOGS
  ADD COLUMN TS_ID TIMESTAMP(12) NOT NULL GENERATED ALWAYS
  AS TRANSACTION START ID IMPLICITLY HIDDEN;

ALTER TABLE LOGDATA.LOGS
  ADD PERIOD SYSTEM_TIME (SYS_START, SYS_END);

CREATE TABLE LOGDATA.LOGS_HIST
  LIKE LOGDATA.LOGS
  IN LOG_DATA_SPACE;

ALTER TABLE LOGDATA.LOGS_HIST
  PCTFREE 0
  APPEND ON
  VOLATILE CARDINALITY;

COMMENT ON TABLE LOGDATA.LOGS_HIST IS 'Table for modified logs';

ALTER TABLE LOGDATA.LOGS
  ADD VERSIONING
  USE HISTORY TABLE LOGDATA.LOGS_HIST;

-- Conf_Loggers
-- The temporal capabilities in this table permits to detect any
-- configuration change (system time), and to prepare a special
-- configuration in the future (business time).

ALTER TABLE LOGDATA.CONF_LOGGERS
  ADD COLUMN BUS_START TIMESTAMP(12) NOT NULL
  DEFAULT CURRENT TIMESTAMP;

-- TODO set date format to prevent issues with inserting.

ALTER TABLE LOGDATA.CONF_LOGGERS
  ADD COLUMN BUS_END TIMESTAMP(12) NOT NULL
  DEFAULT DATE('9999-12-30');

ALTER TABLE LOGDATA.CONF_LOGGERS
  ADD COLUMN SYS_START TIMESTAMP(12) NOT NULL GENERATED ALWAYS
  AS ROW BEGIN IMPLICITLY HIDDEN;

ALTER TABLE LOGDATA.CONF_LOGGERS
  ADD COLUMN SYS_END TIMESTAMP(12) NOT NULL GENERATED ALWAYS
  AS ROW END IMPLICITLY HIDDEN;

ALTER TABLE LOGDATA.CONF_LOGGERS
  ADD COLUMN TS_ID TIMESTAMP(12) NOT NULL GENERATED ALWAYS
  AS TRANSACTION START ID IMPLICITLY HIDDEN;

ALTER TABLE LOGDATA.CONF_LOGGERS
  ADD PERIOD BUSINESS_TIME(BUS_START, BUS_END);

ALTER TABLE LOGDATA.CONF_LOGGERS
  ADD PERIOD SYSTEM_TIME (SYS_START, SYS_END);

ALTER TABLE LOGDATA.CONF_LOGGERS
  ADD CONSTRAINT UNIK_CFG_LOG
  UNIQUE(LOGGER_ID, BUSINESS_TIME WITHOUT OVERLAPS);

CREATE TABLE LOGDATA.CONF_LOGGERS_HIST
  LIKE LOGDATA.CONF_LOGGERS
  IN LOGGER_SPACE;

ALTER TABLE LOGDATA.CONF_LOGGERS_HIST
  PCTFREE 0
  APPEND ON
  VOLATILE CARDINALITY;

COMMENT ON TABLE LOGDATA.CONF_LOGGERS_HIST IS 'Table for modified configuration';

ALTER TABLE LOGDATA.CONF_LOGGERS
  ADD VERSIONING
  USE HISTORY TABLE LOGDATA.CONF_LOGGERS_HIST;

-- Conf_Appenders

ALTER TABLE LOGDATA.CONF_APPENDERS
  ADD COLUMN BUS_START TIMESTAMP(12) NOT NULL
  DEFAULT CURRENT TIMESTAMP;

ALTER TABLE LOGDATA.CONF_APPENDERS
  ADD COLUMN BUS_END TIMESTAMP(12) NOT NULL
  DEFAULT '9999-12-30';

ALTER TABLE LOGDATA.CONF_APPENDERS
  ADD COLUMN SYS_START TIMESTAMP(12) NOT NULL GENERATED ALWAYS
  AS ROW BEGIN IMPLICITLY HIDDEN;

ALTER TABLE LOGDATA.CONF_APPENDERS
  ADD COLUMN SYS_END TIMESTAMP(12) NOT NULL GENERATED ALWAYS
  AS ROW END IMPLICITLY HIDDEN;

ALTER TABLE LOGDATA.CONF_APPENDERS
  ADD COLUMN TS_ID TIMESTAMP(12) NOT NULL GENERATED ALWAYS
  AS TRANSACTION START ID IMPLICITLY HIDDEN;

ALTER TABLE LOGDATA.CONF_APPENDERS
  ADD PERIOD BUSINESS_TIME(BUS_START, BUS_END);

ALTER TABLE LOGDATA.CONF_APPENDERS
  ADD PERIOD SYSTEM_TIME (SYS_START, SYS_END);

ALTER TABLE LOGDATA.CONF_APPENDERS
  ADD CONSTRAINT UNIK_CFG_LOG
  UNIQUE(REF_ID, BUSINESS_TIME WITHOUT OVERLAPS);

CREATE TABLE LOGDATA.CONF_APPENDERS_HIST
  LIKE LOGDATA.CONF_APPENDERS
  IN LOGGER_SPACE;

ALTER TABLE LOGDATA.CONF_APPENDERS_HIST
  PCTFREE 0
  APPEND ON
  VOLATILE CARDINALITY;

COMMENT ON TABLE LOGDATA.CONF_APPENDERS_HIST IS 'Table for modified configuration';

ALTER TABLE LOGDATA.CONF_APPENDERS
  ADD VERSIONING
  USE HISTORY TABLE LOGDATA.CONF_APPENDERS_HIST;

