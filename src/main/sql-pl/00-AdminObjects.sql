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
 * Defines the DDL of many objects:
 * - Bufferpool
 * - Tablespaces
 *
 * Version: 2022-06-08 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

--#SET TERMINATOR @
BEGIN
 DECLARE STMT VARCHAR(512);
 DECLARE OBJECT_EXIST CONDITION FOR SQLSTATE '42710';
 DECLARE CONTINUE HANDLER FOR OBJECT_EXIST
  BEGIN
  END;

 -- Buffer pool for log data.
 SET STMT = 'CREATE BUFFERPOOL LOG_CONF_BP
   PAGESIZE 4K';
 EXECUTE IMMEDIATE STMT;

 -- Buffer pool for log data.
 SET STMT = 'CREATE BUFFERPOOL LOG_BP
  PAGESIZE 8K';
 EXECUTE IMMEDIATE STMT;
 
 -- Tablespace for logger utility.
 SET STMT = 'CREATE TABLESPACE LOGGER_SPACE
   PAGESIZE 4 K
   BUFFERPOOL LOG_CONF_BP';
 EXECUTE IMMEDIATE STMT;
 
 SET STMT = 'COMMENT ON TABLESPACE LOGGER_SPACE IS
   ''log4db2: All configuration tables for the logger utility''';
 EXECUTE IMMEDIATE STMT;
 
 -- Tablespace for logs (data).
 -- PERF: Try to change the configuration to improve the performance:
 -- LARGE tablespace (more rows per page)
 -- EXTENT SIZE (bigger=less preallocation)
 -- PREFETCHSIZE (faster analyses, less sync IO)
 SET STMT = 'CREATE TABLESPACE LOG_DATA_SPACE
   PAGESIZE 8 K
   EXTENTSIZE 64
   PREFETCHSIZE AUTOMATIC
   BUFFERPOOL LOG_BP';
 EXECUTE IMMEDIATE STMT;
 
 SET STMT = 'COMMENT ON TABLESPACE LOGGER_SPACE IS
   ''log4db2: Logs in an independent tablespace''';
 EXECUTE IMMEDIATE STMT;
 
 -- Schema for logger tables.
 SET STMT = 'CREATE SCHEMA LOGDATA';
 EXECUTE IMMEDIATE STMT;
 
 SET STMT = 'COMMENT ON SCHEMA LOGDATA IS
   ''log4db2: Schema for table of the log4db2 utility''';
 EXECUTE IMMEDIATE STMT;
 
 -- Schema for logger utility's objects.
 SET STMT = 'CREATE SCHEMA LOGGER_1';
 EXECUTE IMMEDIATE STMT;
 
 SET STMT = 'COMMENT ON SCHEMA LOGGER_1 IS
   ''log4db2: Schema for objects of the log4db2 utility''';
 EXECUTE IMMEDIATE STMT;

END@

