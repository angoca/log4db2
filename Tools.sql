--#SET TERMINATOR @
SET CURRENT SCHEMA LOGGER @

/**
 * Function that returns the value of the given key from the configuration
 * table.
 *
 * IN KEY
 *  Identification of the key/value parameter of the configuration table.
 * RETURNS The associated value of the given key. NULL if there is not a key
 * with that value.
 */
ALTER MODULE LOGGER ADD
  FUNCTION GET_VALUE (
  IN KEY ANCHOR CONFIGURATION.KEY
  )
  RETURNS ANCHOR CONFIGURATION.VALUE
  LANGUAGE SQL
  PARAMETER CCSID UNICODE
  SPECIFIC F_GET_VAL
  DETERMINISTIC
  NO EXTERNAL ACTION
  READS SQL DATA
  SECURED
 BEGIN
  DECLARE RET ANCHOR CONFIGURATION.KEY;
  SELECT VALUE INTO RET
    FROM CONFIGURATION C
    WHERE C.KEY = KEY
    FETCH FIRST 1 ROW ONLY;
  RETURN RET;
 END @

-- Constant logInternals
ALTER MODULE LOGGER ADD
  VARIABLE LOG_INTERNALS ANCHOR CONFIGURATION.VALUE DEFAULT (
  GET_VALUE ('logInternals')
  ) @