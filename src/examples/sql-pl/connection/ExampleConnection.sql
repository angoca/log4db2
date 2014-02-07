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

SET CURRENT SCHEMA TESTS @

SET PATH = "SYSIBM","SYSFUN","SYSPROC","SYSIBMADM", LOGGER_1A @

CREATE SCHEMA TESTS @

CREATE OR REPLACE PROCEDURE TESTS.CONNECTION_SETUP()
BEGIN
 -- Do nothing if there is a problem.
 CALL LOGGER.FATAL(0, 'Connection established by ' || CURRENT USER);
END @

--#SET TERMINATOR ;
UPDATE DB CFG USING CONNECT_PROC TESTS.CONNECTION_SETUP;
 
CONNECT RESET;

-------------------------------------------------------------------------------
--#SET TERMINATOR @
-- The following statements are to reverse the configuration.
CONNECT TO LOG4DB2@

UPDATE DB CFG USING CONNECT_PROC NULL@

DROP PROCEDURE TESTS.CONNECTION_SETUP@

DROP SCHEMA TESTS RESTRICT@

CONNECT RESET@