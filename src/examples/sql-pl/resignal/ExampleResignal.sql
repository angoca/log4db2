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

/**
 * Example to log a generated signal and resignal.
 *
 * Version: 2014-04-21 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET PATH = TESTS, LOGGER_1RC @

CREATE SCHEMA TESTS @

CREATE OR REPLACE PROCEDURE DIVISION (
  IN NUMERATOR INTEGER,
  IN DENOMINATOR INTEGER,
  OUT RESULT INTEGER
  )
  SPECIFIC P_DIVISION
P_DIVISION: BEGIN
 DECLARE LOGGER_ID SMALLINT;
 DECLARE ZERO_DIVISION CONDITION FOR SQLSTATE '22012';
 DECLARE EXIT HANDLER FOR ZERO_DIVISION
  BEGIN
   CALL LOGGER.FATAL(LOGGER_ID, 'Error, SQLSTATE 22012');
   RESIGNAL SQLSTATE 'DIV01';
  END;

 -- Retrieves the Id for the logger of the given name.
 CALL LOGGER.GET_LOGGER('DIVISION', LOGGER_ID);
 
 -- Depending on the Logger configuration, some messages are not logged.
 CALL LOGGER.DEBUG(LOGGER_ID, '> DIVISION');
 
 IF (DENOMINATOR = 0) THEN
  SIGNAL ZERO_DIVISION;
 ELSE
  CALL LOGGER.INFO(LOGGER_ID, 'Dividing');
  SET RESULT = NUMERATOR / DENOMINATOR;
 END IF;
 CALL LOGGER.DEBUG(LOGGER_ID, '< DIVISION');
END P_DIVISION @

BEGIN
 DECLARE RESULT INTEGER;
 DECLARE CONTINUE HANDLER FOR SQLSTATE 'DIV01'
   CALL LOGGER.ERROR(0, 'Zero division');
 CALL TESTS.DIVISION(6, 2, RESULT);
 -- The next call raised a signal: DIV01
 CALL TESTS.DIVISION(6, 0, RESULT);
END @

DROP PROCEDURE TESTS.DIVISION (INTEGER, INTEGER, INTEGER) @

DROP SCHEMA TESTS RESTRICT @

!echo "If the schema called 'tests' cannot be dropped, terminate the session," @
!echo "reconnect and issue again the command: DROP SCHEMA TESTS RESTRICT" @

