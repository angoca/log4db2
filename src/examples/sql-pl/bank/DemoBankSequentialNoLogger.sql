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

SET CURRENT SCHEMA DEMOBANK @

/**
 * Semi sequential execution of the DemoBank without logger.
 *
 * Version: 2014-04-21 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

SET PATH = "SYSIBM","SYSFUN","SYSPROC","SYSIBMADM", DEMOBANK, LOGGER_1RC @

BEGIN
 DECLARE TYPE FN_TYPE AS VARCHAR(32) ARRAY [10];
 DECLARE TYPE LN_TYPE AS VARCHAR(32) ARRAY [10];
 DECLARE SQLCODE INTEGER DEFAULT 0;
 DECLARE SQLSTATE CHAR(5) DEFAULT '0000';
 DECLARE ACCOUNT INTEGER;
 DECLARE ITERATION INTEGER DEFAULT 0;
 DECLARE FIRST_NAMES FN_TYPE;
 DECLARE LAST_NAMES LN_TYPE;
 -- No logger
 -- No logger
 -- No logger

 -- No logger

 -- No logger
 COMMIT;

 SET FIRST_NAMES[1] = 'Andres';
 SET FIRST_NAMES[2] = 'David';
 SET FIRST_NAMES[3] = 'Humberto';
 SET FIRST_NAMES[4] = 'Alicia';
 SET FIRST_NAMES[5] = 'Olga';
 SET FIRST_NAMES[6] = 'Rafael';
 SET FIRST_NAMES[7] = 'Angelica';
 SET FIRST_NAMES[8] = 'Oscar';
 SET FIRST_NAMES[9] = 'Liliana';
 SET FIRST_NAMES[10] = 'Eugenia';
 SET LAST_NAMES[1] = 'Gomez';
 SET LAST_NAMES[2] = 'Casanova';
 SET LAST_NAMES[3] = 'Alvarez';
 SET LAST_NAMES[4] = 'Sanchez';
 SET LAST_NAMES[5] = 'Ortiz';
 SET LAST_NAMES[6] = 'Orjuela';
 SET LAST_NAMES[7] = 'Ceron';
 SET LAST_NAMES[8] = 'Jurado';
 SET LAST_NAMES[9] = 'Martinez';
 SET LAST_NAMES[10] = 'Jimenez';

 -- No logger
 BEGIN
  DECLARE FNAME VARCHAR(32);
  DECLARE LNAME VARCHAR(32);
  DECLARE IND SMALLINT;
  -- Picks a name.
  SET IND = RAND() * CARDINALITY(FIRST_NAMES);
  IF (IND <= 0 OR IND > 10) THEN
   SET IND = 1;
  END IF;
  SET FNAME = FIRST_NAMES[IND];
  -- Picks a last name.
  SET IND = RAND() * CARDINALITY(LAST_NAMES);
  IF (IND <= 0 OR IND > 10) THEN
   SET IND = 1;
  END IF;
  SET LNAME = LAST_NAMES[IND];
  CALL DEMOBANK.CREATE_ACCOUNT(LNAME, FNAME, ACCOUNT);
  COMMIT;
 END;
 WHILE (ITERATION < 10000) DO
  -- No logger
   -- No logger
  -- No logger
  BEGIN
   CASE
    WHEN ITERATION = 1 OR MOD(ITERATION, 8) = 1 OR MOD(ITERATION, 8) = 2 THEN -- Deposit.
     -- No logger
     BEGIN
      DECLARE ACC_NB INTEGER;
      DECLARE AMOUNT INTEGER;
      -- Picks a random account.
      SELECT ACCOUNT_NUM INTO ACC_NB
      FROM ACCOUNTS
      ORDER BY RAND()
      FETCH FIRST 1 ROW ONLY;
      SET AMOUNT = RAND() * 1000;
      IF (ACC_NB IS NOT NULL) THEN
       CALL DEMOBANK.DEPOSIT(ACC_NB, AMOUNT);
      -- No logger
       -- No logger
      END IF;
      COMMIT;
     END;
    WHEN MOD(ITERATION, 8) >= 3 THEN -- Withdrawal.
     -- No logger
     BEGIN
      DECLARE ACC_NB INTEGER;
      DECLARE AMOUNT INTEGER;
      -- Picks a random account.
      SELECT ACCOUNT_NUM INTO ACC_NB
      FROM ACCOUNTS
      ORDER BY RAND()
      FETCH FIRST 1 ROW ONLY;
      SET AMOUNT = RAND() * 100;
      IF (ACC_NB IS NOT NULL) THEN
       CALL DEMOBANK.WITHDRAWAL(ACC_NB, AMOUNT);
      -- No logger
       -- No logger
      END IF;
      COMMIT;
     END;
    ELSE -- Gets the balance.
     -- No logger
     BEGIN
      DECLARE ACC_NB INTEGER;
      DECLARE BAL INTEGER;
      -- Picks a random account.
      SELECT ACCOUNT_NUM INTO ACC_NB
      FROM ACCOUNTS
      ORDER BY RAND()
      FETCH FIRST 1 ROW ONLY;
      IF (ACC_NB IS NOT NULL) THEN
       CALL DEMOBANK.GET_BALANCE(ACC_NB, BAL);
       -- No logger
      -- No logger
       -- No logger
      END IF;
      COMMIT;
     END;
    END CASE;
  END;
  SET ITERATION = ITERATION + 1;
 END WHILE;

 -- No logger
 BEGIN
  CALL DEMOBANK.CLOSE_ACCOUNT(ACCOUNT);
  COMMIT;
 END;
 -- No logger
END @

