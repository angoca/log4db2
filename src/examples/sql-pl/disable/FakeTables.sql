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

SET CURRENT SCHEMA FAKELOGDATA;

/**
 * Defines the DDL of many objects:
 * - Bufferpool
 * - Tablespaces
 * - Tables
 * - Sequences
 * - Referential integrity
 * And also some DML for the basic content for the utility to run.
 *
 * Version: 2014-05-24 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

-- Schema for logger tables.
CREATE SCHEMA FAKELOGDATA;

-- Table for the global configuration of the logger utility.
CREATE TABLE CONFIGURATION (
  KEY VARCHAR(32) NOT NULL,
  VALUE VARCHAR(256) NULL
  );

-- Table for the logger levels.
CREATE TABLE LEVELS (
  LEVEL_ID SMALLINT NOT NULL,
  NAME CHAR(5) NOT NULL
  );

-- Table for loggers configuration.
CREATE TABLE CONF_LOGGERS (
  LOGGER_ID SMALLINT NOT NULL,
  NAME VARCHAR(256) NOT NULL,
  PARENT_ID SMALLINT,
  LEVEL_ID SMALLINT
  );

-- Table for the effecetive loggers configuration.
-- This table allows to keep an id related to a specific logger across database
-- activations.
CREATE TABLE CONF_LOGGERS_EFFECTIVE
  LIKE CONF_LOGGERS;

-- Table for the appenders.
CREATE TABLE APPENDERS (
  APPENDER_ID SMALLINT NOT NULL,
  NAME VARCHAR(256) NOT NULL
  );

-- Table for the configuration about where to write the logs.
CREATE TABLE CONF_APPENDERS (
  REF_ID SMALLINT NOT NULL,
  NAME CHAR(32),
  APPENDER_ID SMALLINT NOT NULL,
  CONFIGURATION XML INLINE LENGTH 1000,
  PATTERN VARCHAR(256),
  LEVEL_ID SMALLINT
  );

-- Table for the loggers and appenders association.
CREATE TABLE REFERENCES (
  LOGGER_ID SMALLINT NOT NULL,
  APPENDER_REF_ID SMALLINT NOT NULL
  );

-- Table for the pure SQL Tables appender.
CREATE TABLE LOGS (
  DATE_UNIQ CHAR(13) FOR BIT DATA NOT NULL IMPLICITLY HIDDEN,
  TIMESTAMP TIMESTAMP,
  LEVEL_ID SMALLINT,
  LOGGER_ID SMALLINT,
  MESSAGE VARCHAR(512) NOT NULL
  );

