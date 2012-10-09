--#SET TERMINATOR @
SET CURRENT SCHEMA DEMOBANK @

BEGIN
 DECLARE TYPE FN_TYPE AS VARCHAR(32) ARRAY [10];
 DECLARE TYPE LN_TYPE AS VARCHAR(32) ARRAY [10];
 DECLARE ITERATION INTEGER DEFAULT 0;
 DECLARE FIRST_NAMES FN_TYPE;
 DECLARE LAST_NAMES LN_TYPE;
 
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

 WHILE (ITERATION < 1000) DO
  BEGIN
   DECLARE OPER SMALLINT;
   SET OPER = RAND() * 100;
   CASE
    WHEN OPER <= 5 THEN -- Create account.
     BEGIN
      DECLARE FNAME VARCHAR(32);
      DECLARE LNAME VARCHAR(32);
      DECLARE IND SMALLINT;
      -- Picks a name.
      SET IND = RAND() * 10;
      IF (IND <= 0 OR IND > 10) THEN
       SET IND = 1;
      END IF;
      SET FNAME = FIRST_NAMES[IND];
      -- Picks a last name.
      SET IND = RAND() * 10;
      IF (IND <= 0 OR IND > 10) THEN
       SET IND = 1;
      END IF;
      SET LNAME = LAST_NAMES[IND];
      CALL DEMOBANK.CREATE_ACCOUNT(LNAME, FNAME);
      COMMIT;
     END;
    WHEN 6 <= OPER AND OPER <= 15 THEN -- Gets the balance.
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
      END IF;
      COMMIT;
     END;
    WHEN 16 <= OPER AND OPER <= 30 THEN -- Deposit.
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
      END IF;
      COMMIT;
     END;
    WHEN 31 <= OPER AND OPER <= 90 THEN -- Withdrawal.
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
      END IF;
      COMMIT;
     END;
    WHEN 91 <= OPER AND OPER <= 98 THEN -- Transfer.
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
      END IF;
      COMMIT;
     END;
    ELSE
     BEGIN
      DECLARE ACC_NB INTEGER;
      -- Picks a random account.
      SELECT ACCOUNT_NUM INTO ACC_NB
      FROM ACCOUNTS
      ORDER BY RAND()
      FETCH FIRST 1 ROW ONLY;
      IF (ACC_NB IS NOT NULL) THEN
      CALL DEMOBANK.CLOSE_ACCOUNT(ACC_NB);
      END IF;
      COMMIT;
     END;
    END CASE;
  END;
  SET ITERATION = ITERATION + 1;
 END WHILE;
END@