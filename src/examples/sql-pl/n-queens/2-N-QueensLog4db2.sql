--#SET TERMINATOR @

/*
Copyright (c) 2022 - 2022, Andres Gomez Casanova (AngocA)
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

-- Set of procedures to solve the n-queens problem.
--
-- Author: Andres Gomez Casanova (AngocA)
-- Version: 2022-06-02 1-RC
-- Made in COLOMBIA.

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
  DECLARE LOGGER_ID SMALLINT;

  DECLARE I SMALLINT;
  DECLARE J SMALLINT;
  DECLARE VAL INTEGER;
  
  CALL LOGGER.GET_LOGGER('N_QUEENS.IS_SAFE', LOGGER_ID);
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
  DECLARE LOGGER_ID SMALLINT;

  DECLARE I SMALLINT;
  DECLARE SAFE BOOLEAN;
  DECLARE SOLVED BOOLEAN;

  CALL LOGGER.GET_LOGGER('N_QUEENS.SOLVE_N_QUEENS', LOGGER_ID);

  CALL LOGGER.INFO(LOGGER_ID, 'Starting COL:' || COL);
  -- Debug purposes.
  --CALL PRINT_INTEGER_MATRIX(M);
  SET RET = FALSE;
  IF (COL > SIZE) THEN
   CALL LOGGER.INFO(LOGGER_ID, 'Column limit');
   SET RET = TRUE;
  ELSE
   SET I = 1;
   WHILE (I <= SIZE AND NOT RET) DO
    CALL LOGGER.DEBUG(LOGGER_ID, 'Checking if safe');
    SET SAFE = IS_SAFE(M, I, COL, SIZE);
    IF (SAFE) THEN
     CALL SET_INTEGER_VALUE(I, COL, M, 1);
     CALL LOGGER.DEBUG(LOGGER_ID, 'Recurssion');
     CALL SOLVE_N_QUEENS(M, SIZE, COL + 1, SOLVED);
     IF (SOLVED) THEN
      CALL LOGGER.DEBUG(LOGGER_ID, 'Finishing: I:' || I || ',COL:' || COL || '-true');
      SET RET = TRUE;
     ELSE
      CALL SET_INTEGER_VALUE(I, COL, M, 0); -- Backtrack.
     END IF;
    
    END IF;
  
    SET I = I + 1;
   END WHILE;

  END IF;
  CALL LOGGER.INFO(LOGGER_ID, 'Finishing: COL:' || COL || '-false');

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
  DECLARE LOGGER_ID SMALLINT;
  
  DECLARE M INTEGER_MATRIX;
  DECLARE SOL BOOLEAN DEFAULT FALSE;
  
  CALL LOGGER.GET_LOGGER('N_QUEENS.main', LOGGER_ID);
  
  CALL LOGGER.ERROR(LOGGER_ID, 'Starting...');
  CALL INIT_INTEGER_MATRIX(M, SIZE, SIZE, 0);
 
  CALL LOGGER.WARN(LOGGER_ID, 'Finding solution...');
  CALL SOLVE_N_QUEENS(M, SIZE, 1, SOL);
  IF (SOL = TRUE) THEN
   CALL PRINT_INTEGER_MATRIX(M);
  ELSE
   CALL LOGGER.WARN(LOGGER_ID, 'Solution does not exist');
   CALL DBMS_OUTPUT.PUT_LINE('Solution does not exist.');
  END IF;
  
 END P_N_QUEENS
@

