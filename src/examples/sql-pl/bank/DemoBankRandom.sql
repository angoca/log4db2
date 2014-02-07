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

SET PATH = "SYSIBM","SYSFUN","SYSPROC","SYSIBMADM", DEMOBANK, LOGGER_1A @

BEGIN
 DECLARE TYPE FN_TYPE AS VARCHAR(32) ARRAY [10];
 DECLARE TYPE LN_TYPE AS VARCHAR(32) ARRAY [10];
 DECLARE SQLCODE INTEGER DEFAULT 0;
 DECLARE SQLSTATE CHAR(5) DEFAULT '0000';
 DECLARE ITERATION INTEGER DEFAULT 0;
 DECLARE FIRST_NAMES FN_TYPE;
 DECLARE LAST_NAMES LN_TYPE;
 DECLARE LOGGER_ID SMALLINT;
 DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
   CALL LOGGER.FATAL(LOGGER_ID, 'Exception: SQLCODE ' || SQLCODE || ' - SQLState ' || SQLSTATE);
 
 CALL LOGGER.GET_LOGGER('DemoBank.Simulation', LOGGER_ID);
 
 CALL LOGGER.ERROR (LOGGER_ID, 'Starting simulation');

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

 WHILE (ITERATION < 10000) DO
  CALL LOGGER.INFO (LOGGER_ID, 'Iteration ' || ITERATION);
  BEGIN
   DECLARE OPER SMALLINT;
   SET OPER = RAND() * 100;
   CASE
    WHEN OPER <= 5 THEN -- Create account.
     CALL LOGGER.INFO (LOGGER_ID, 'Create account option');
     BEGIN
      DECLARE FNAME VARCHAR(32);
      DECLARE LNAME VARCHAR(32);
      DECLARE IND SMALLINT;
      DECLARE ACCOUNT INTEGER;
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
    WHEN 6 <= OPER AND OPER <= 15 THEN -- Gets the balance.
     CALL LOGGER.INFO (LOGGER_ID, 'Get balance option');
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
       CALL LOGGER.DEBUG (LOGGER_ID, 'The balance for the ' || ACC_NB || ' account is ' || BAL);
      ELSE
       CALL LOGGER.DEBUG (LOGGER_ID, 'Invalid account');
      END IF;
      COMMIT;
     END;
    WHEN 16 <= OPER AND OPER <= 30 THEN -- Deposit.
     CALL LOGGER.INFO (LOGGER_ID, 'Deposit option');
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
      ELSE
       CALL LOGGER.DEBUG (LOGGER_ID, 'Invalid account');
      END IF;
      COMMIT;
     END;
    WHEN 31 <= OPER AND OPER <= 90 THEN -- Withdrawal.
     CALL LOGGER.INFO (LOGGER_ID, 'Withdrawal option');
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
      ELSE
       CALL LOGGER.DEBUG (LOGGER_ID, 'Invalid account');
      END IF;
      COMMIT;
     END;
    WHEN 91 <= OPER AND OPER <= 98 THEN -- Transfer.
     CALL LOGGER.INFO (LOGGER_ID, 'Tranfer option');
     BEGIN
      DECLARE ACC_NB_SC INTEGER;
      DECLARE ACC_NB_TG INTEGER;
      DECLARE AMOUNT INTEGER;
      -- Picks random accounts.
      SELECT ACCOUNT_NUM INTO ACC_NB_SC
      FROM ACCOUNTS
      ORDER BY RAND()
      FETCH FIRST 1 ROW ONLY;
      SELECT ACCOUNT_NUM INTO ACC_NB_TG
      FROM ACCOUNTS
      ORDER BY RAND()
      FETCH FIRST 1 ROW ONLY;
      SET AMOUNT = RAND() * 10000;
      IF (ACC_NB_SC IS NOT NULL AND ACC_NB_TG IS NOT NULL) THEN
       CALL DEMOBANK.TRANSFER(ACC_NB_SC, ACC_NB_TG, AMOUNT);
      ELSE
       CALL LOGGER.DEBUG (LOGGER_ID, 'Invalid account');
      END IF;
      COMMIT;
     END;
    ELSE
     CALL LOGGER.INFO (LOGGER_ID, 'Delete account option');
     BEGIN
      DECLARE ACC_NB INTEGER;
      -- Picks a random account.
      SELECT ACCOUNT_NUM INTO ACC_NB
      FROM ACCOUNTS
      ORDER BY RAND()
      FETCH FIRST 1 ROW ONLY;
      IF (ACC_NB IS NOT NULL) THEN
       CALL DEMOBANK.CLOSE_ACCOUNT(ACC_NB);
      ELSE
       CALL LOGGER.DEBUG (LOGGER_ID, 'Invalid account');
      END IF;
      COMMIT;
     END;
    END CASE;
  END;
  SET ITERATION = ITERATION + 1;
 END WHILE;
 
 CALL LOGGER.ERROR (LOGGER_ID, 'Ending simulation');
END @

