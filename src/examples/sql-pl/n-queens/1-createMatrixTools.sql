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

-- Set of procedures to deal with matrix (array of arrays) in Db2.
-- This set procedures provides the following commands:
-- * Init the matrix with a value.
-- * Get a value from the matrix.
-- * Set a value in a position of the matrix.
-- * Print the matrix in the std out. It is necessary to use 
--   SERVEROUTPUT ON.
--
-- Author: Andres Gomez Casanova (AngocA)
-- Version: 2022-06-02 1-RC
-- Made in COLOMBIA.

-- A column of a matrix.
CREATE TYPE INTEGER_ARRAY AS INTEGER ARRAY[]@
-- The whole matrix of any size.
CREATE TYPE INTEGER_MATRIX AS INTEGER_ARRAY ARRAY[]@
 
/**
 * Retrieves the value from a matrix at a specific position.
 * 
 * IN X: Row number.
 * IN Y: Column number.
 * IN M: Matrix.
 * RETURN the integer value at that position.
 */
CREATE OR REPLACE FUNCTION GET_INTEGER_VALUE(
  IN X SMALLINT,
  IN Y SMALLINT,
  IN M INTEGER_MATRIX)
RETURNS INTEGER
F_GET_INTEGER_VALUE: BEGIN
  DECLARE A INTEGER_ARRAY;
  DECLARE RET INTEGER;
 
  SET A = M[X];
  SET RET = A[Y];
  RETURN RET;
END F_GET_INTEGER_VALUE
@

/**
 * Establishes the given value at a specific position in the matrix.
 * 
 * IN X: Row number.
 * IN Y: Column number.
 * INOUT M: Matrix.
 * IN VAL: Value to set in the matrix.
 */
CREATE OR REPLACE PROCEDURE SET_INTEGER_VALUE(
  IN X SMALLINT,
  IN Y SMALLINT,
  INOUT M INTEGER_MATRIX,
  IN VAL INTEGER)
P_SET_INTEGER_VALUE: BEGIN
  DECLARE A INTEGER_ARRAY;
 
  SET A = M[X];
  SET A[Y] = VAL;
  SET M[X] = A;
END P_SET_INTEGER_VALUE
@

/**
 * Initializes the matriz at a given size with the same value in all positions.
 * 
 * INOUT M: Matrix.
 * IN X: Number of rows.
 * IN Y: Number of columns per row.
 * IN VAL: Value to set in the matrix.
 */
CREATE OR REPLACE PROCEDURE INIT_INTEGER_MATRIX(
  INOUT M INTEGER_MATRIX,
  IN X SMALLINT,
  IN Y SMALLINT,
  IN VAL INTEGER)
P_INIT_INTEGER_MATRIX: BEGIN
  DECLARE I SMALLINT DEFAULT 1;
  DECLARE J SMALLINT;
  DECLARE A INTEGER_ARRAY;
 
  WHILE (I <= X) DO
   SET A = ARRAY[];
   SET J = 1;
   WHILE (J <= Y) DO
    SET A[J] = VAL;
    SET J = J + 1;
   END WHILE;
   SET M[I] = A;
   SET I = I + 1;
  END WHILE;
END P_INIT_INTEGER_MATRIX
@

/**
 * Prints the content of the matrix to the standard output.
 * 
 * INOUT M: Matrix.
 */
CREATE OR REPLACE PROCEDURE PRINT_INTEGER_MATRIX(
  IN M INTEGER_MATRIX)
P_PRINT_INTEGER_MATRIX: BEGIN
  DECLARE I SMALLINT DEFAULT 1;
  DECLARE J SMALLINT;
  DECLARE X SMALLINT;
  DECLARE Y SMALLINT;
  DECLARE VAL INTEGER;
  DECLARE A INTEGER_ARRAY;
  DECLARE RET VARCHAR(256);
 
  SET X = CARDINALITY(M);
  CALL DBMS_OUTPUT.PUT_LINE('>>>>>');
  WHILE (I <= X) DO
   SET A = M[I];
   SET RET = '[';
   SET Y = CARDINALITY(A);
   SET J = 1;
   WHILE (J <= Y) DO
    SET VAL = A[J];
    SET RET = RET || VAL;
    SET J = J + 1;
    IF (J <= Y) THEN
     SET RET = RET || ',';
    END IF;
   END WHILE;
   SET RET = RET || ']';
   CALL DBMS_OUTPUT.PUT_LINE(RET);
   SET I = I + 1;
  END WHILE;
  CALL DBMS_OUTPUT.PUT_LINE('<<<<<');
END P_PRINT_INTEGER_MATRIX
@

