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

SET CURRENT SCHEMA LOGDATA;

/**
 * Defines the DDL for the LOGS table which is the most important and used table
 * in this project. When using a partitioned table, it is necessary to create a
 * partition just after the installation in order to use the utility.
 *
 * Version: 2022-06-03 v1
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */


--#SET TERMINATOR @
-- Table for the pure SQL Tables appender.
-- TODO make tests in order to check in a auto generated column for an id
-- does not impact the performance, and provides a better way to sort messages.
-- This ID column could be hidden to the user. The benefit is that the logs
-- could be accessed via an index, but it impacts the writes, because this
-- structure has to be maintained.
BEGIN
  DECLARE STMT VARCHAR(512);

  SET STMT = 'CREATE TABLE LOGS ('
    || 'DATE_UNIQ CHAR(13) FOR BIT DATA NOT NULL IMPLICITLY HIDDEN, '
    || 'TIMESTAMP TIMESTAMP DEFAULT CURRENT TIMESTAMP, '
    || 'LEVEL_ID SMALLINT, '
    || 'LOGGER_ID SMALLINT, '
    || 'MESSAGE VARCHAR(512) NOT NULL '
    || ') IN LOG_DATA_SPACE '
    || 'PARTITION BY RANGE (TIMESTAMP)( '
    || 'STARTING ''' || (CURRENT DATE - 1 DAY)
    || ''' ENDING ''' || (CURRENT DATE) || ''' EXCLUSIVE EVERY 1 DAY)';
  -- Debug
  -- CALL DBMS_OUTPUT.PUT_LINE(STMT);
  EXECUTE IMMEDIATE STMT;
END@

--#SET TERMINATOR ;

CREATE INDEX IDX_LOGS ON LOGS (TIMESTAMP);

ALTER TABLE LOGS
  PCTFREE 0
  APPEND ON
  VOLATILE CARDINALITY;

-- PERF: Not Logged Initially could improve the performance, but it does not
-- work for HADR or other facilities based on transaction logs.
-- ALTER TABLE LOGS
--   ACTIVATE NOT LOGGED INITIALLY;

COMMENT ON TABLE LOGS IS 'Table where the logs are written';

COMMENT ON LOGS (
  DATE_UNIQ IS 'Unique date',
  TIMESTAMP IS 'Date where the event was reported. Could be repeated',
  LEVEL_ID IS 'Log level',
  LOGGER_ID IS 'Logger that generated this message',
  MESSAGE IS 'Message logged'
  );

CREATE OR REPLACE PUBLIC ALIAS LOGS FOR TABLE LOGS;

COMMENT ON PUBLIC ALIAS LOGS IS 'log4db2 logs';

RUNSTATS ON TABLE LOGDATA.LOGS ON ALL COLUMNS AND INDEXES ALL;

