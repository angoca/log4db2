--#SET TERMINATOR @
SET CURRENT SCHEMA LOGGER @

/**
 * This trigger checks the insertion in the conf_logger table to see
 * if the logger_id already exists in the conf_logger_effective table.
 * There should exist the record in the effective table before than in this
 * table.
 * The initial intent was a trigger that inserted the row in the effective
 * table, as a "before" trigger. However, insert operations are now allowed in
 * this kind of triggers.
 */
CREATE OR REPLACE TRIGGER CHECK_CONF_LOGGER_EFFECTIVE
  BEFORE UPDATE OR INSERT ON CONF_LOGGERS
  REFERENCING NEW AS N
  FOR EACH ROW
 T_CHK_CONG_LOGGER: BEGIN
  DECLARE EXISTING_ID ANCHOR CONF_LOGGERS.LOGGER_ID;
  -- Retrieves the current ID from the effective table.
  -- Select Into is not allowed here, and I do not know why.
  SET EXISTING_ID = (SELECT LOGGER_ID
    FROM CONF_LOGGERS_EFFECTIVE E
    WHERE E.LOGGER_ID = N.LOGGER_ID);
  -- Checks if the id exists in the effective table.
  IF (EXISTING_ID IS NULL) THEN
   -- It does not exist, then raise a signal.
   SIGNAL SQLSTATE VALUE 'LG001'
     SET MESSAGE_TEXT = 'Logger not defined in Effective table';
  ELSEIF (N.LOGGER_ID <> 0) THEN
   -- Checks that the only logger without parent is ROOT.
   IF (N.PARENT_ID IS NULL) THEN
    -- Raises an error.
    SIGNAL SQLSTATE VALUE 'LG002'
      SET MESSAGE_TEXT = 'The only logger without parent is ROOT';
   END IF;
  END IF;
 END T_CHK_CONG_LOGGER @

/**
 * Verifies that the root logger is not deleted from the effective table. This
 * is the basic logger and it should always exist in this table.
 */
CREATE OR REPLACE TRIGGER ROOT_LOGGER_UNDELETABLE
  BEFORE DELETE ON CONF_LOGGERS_EFFECTIVE
  REFERENCING OLD AS O
  FOR EACH ROW
 WHEN (O.LOGGER_ID = 0)
  T_UNDELETABLE: BEGIN
   SIGNAL SQLSTATE VALUE 'LG003'
     SET MESSAGE_TEXT = 'ROOT logger cannot be deleted';
  END T_UNDELETABLE