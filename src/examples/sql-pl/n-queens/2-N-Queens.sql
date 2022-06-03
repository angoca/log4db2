--#SET TERMINATOR @

-- Set of procedures to solve the n-queens problem.
--
-- Author: Andres Gomez
-- Version: 20220529

/**
 * Checks if a queen is safe in the given position.
 * 
 * IN M: Matrix representing the chessboard.
 * IN ROW: Row of the queen.
 * IN COL: Column in the row for the queen.
 * IN SIZE: Size of the chessboard (max row, max col).
 * RETURNS true if the position is safe.
 */
CREATE OR REPLACE FUNCTION IS_SAFE(
  IN M INTEGER_MATRIX,
  IN ROW SMALLINT,
  IN COL SMALLINT,
  IN SIZE SMALLINT)
 MODIFIES SQL DATA
 RETURNS BOOLEAN
 F_IS_SAFE: BEGIN
  DECLARE I SMALLINT;
  DECLARE J SMALLINT;
  DECLARE VAL INTEGER;
  
  -- Debug purposes.
  --CALL SET_INTEGER_VALUE(ROW, COL, M, -1);
  --CALL PRINT_INTEGER_MATRIX(M);
  --CALL SET_INTEGER_VALUE(ROW, COL, M, 0);

  SET I = 1;
  WHILE (I <= COL) DO
   SET VAL = GET_INTEGER_VALUE(ROW, I, M);
   IF (VAL = 1) THEN
    RETURN FALSE;
   END IF;
   SET I = I + 1;
  END WHILE;
 
  SET I = ROW;
  SET J = COL;
  WHILE (I >= 1 AND J >= 1) DO
   SET VAL = GET_INTEGER_VALUE(I, J, M);
   IF (VAL = 1) THEN
    CALL SET_INTEGER_VALUE(ROW, COL, M, 0);
    RETURN FALSE;
   END IF;
   SET I = I - 1;
   SET J = J - 1;
  END WHILE;

  SET I = ROW;
  SET J = COL;
  WHILE (J >= 1 AND I <= SIZE) DO
   SET VAL = GET_INTEGER_VALUE(I, J, M);
   IF (VAL = 1) THEN
    RETURN FALSE;
   END IF;
   SET I = I + 1;
   SET J = J - 1;
  END WHILE;

  RETURN TRUE;
 END F_IS_SAFE
@

/**
 * Dummy procedure for the recurssion.
 * 
 * IN SIZE: Size of the chessboard (max row, max col).
 * IN COL: Column to analyse.
 * OUT RET: True if it was possible to put all queens
 */
CREATE OR REPLACE PROCEDURE SOLVE_N_QUEENS(
  INOUT M INTEGER_MATRIX,
  IN SIZE SMALLINT,
  IN COL SMALLINT,
  OUT RET BOOLEAN)
 P_SOLVE_N_QUEENS: BEGIN
 END P_SOLVE_N_QUEENS
@

/**
 * Solves the n-queens algoritm.
 * 
 * IN SIZE: Size of the chessboard (max row, max col).
 * IN COL: Column to analyse.
 * OUT RET: True if it was possible to put all queens
 */
CREATE OR REPLACE PROCEDURE SOLVE_N_QUEENS(
  INOUT M INTEGER_MATRIX,
  IN SIZE SMALLINT,
  IN COL SMALLINT,
  OUT RET BOOLEAN)
 MODIFIES SQL DATA
 P_SOLVE_N_QUEENS: BEGIN
  DECLARE I SMALLINT;
  DECLARE SAFE BOOLEAN;
  DECLARE SOLVED BOOLEAN;

  -- Debug purposes.
  --CALL PRINT_INTEGER_MATRIX(M);
  SET RET = FALSE;
  IF (COL > SIZE) THEN
   SET RET = TRUE;
  ELSE
   SET I = 1;
   WHILE (I <= SIZE AND NOT RET) DO
    SET SAFE = IS_SAFE(M, I, COL, SIZE);
    IF (SAFE) THEN
     CALL SET_INTEGER_VALUE(I, COL, M, 1);
     CALL SOLVE_N_QUEENS(M, SIZE, COL + 1, SOLVED);
     IF (SOLVED) THEN
      SET RET = TRUE;
     ELSE
      CALL SET_INTEGER_VALUE(I, COL, M, 0); -- Backtrack.
     END IF;
    
    END IF;
  
    SET I = I + 1;
   END WHILE;

  END IF;
 END P_SOLVE_N_QUEENS
@

/**
 * Main procedure to solve the n-queen algoritm.
 * 
 * IN SIZE: Size of the chessboard. The bigger it is, the more time it takes.
 */
CREATE OR REPLACE PROCEDURE N_QUEENS(
  IN SIZE SMALLINT)
 P_N_QUEENS: BEGIN
  DECLARE M INTEGER_MATRIX;
  DECLARE SOL BOOLEAN DEFAULT FALSE;
  
  CALL INIT_INTEGER_MATRIX(M, SIZE, SIZE, 0);
 
  CALL SOLVE_N_QUEENS(M, SIZE, 1, SOL);
  IF (SOL = TRUE) THEN
   CALL PRINT_INTEGER_MATRIX(M);
  ELSE
   CALL DBMS_OUTPUT.PUT_LINE('Solution does not exist.');
  END IF;
  
 END P_N_QUEENS
@

