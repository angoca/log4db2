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
CREATE OR REPLACE TRIGGER CHECK_CONF_LOGGER
  BEFORE UPDATE OR INSERT ON LOGDATA.CONF_LOGGERS
  REFERENCING NEW AS N
  FOR EACH ROW
 T_CHK_CONF_LOGGER: BEGIN
  DECLARE EXISTING_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  -- Retrieves the current ID from the effective table.
  -- Select Into is not allowed here, and I do not know why.
  SET EXISTING_ID = (SELECT LOGGER_ID
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE E
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
 END T_CHK_CONF_LOGGER @

/**
 * Verifies that the parent is not null. The only logger with null parent is
 * root.
 */
CREATE OR REPLACE TRIGGER CHECK_CONF_LOGGER_EFFECTIVE
  BEFORE INSERT OR UPDATE ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING NEW AS N
  FOR EACH ROW
 WHEN (N.PARENT_ID IS NULL AND N.LOGGER_ID <> 0)
  T_CHK_CONF_LOGGER_EFFECTIVE: BEGIN
   SIGNAL SQLSTATE VALUE 'LG002'
     SET MESSAGE_TEXT = 'The only logger without parent is ROOT';
  END T_CHK_CONF_LOGGER_EFFECTIVE @

/**
 * Verifies that the root logger is not deleted from the effective table. This
 * is the basic logger and it should always exist in this table.
 */
CREATE OR REPLACE TRIGGER ROOT_LOGGER_UNDELETABLE
  BEFORE DELETE ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING OLD AS O
  FOR EACH ROW
 WHEN (O.LOGGER_ID = 0)
  T_UNDELETABLE: BEGIN
   SIGNAL SQLSTATE VALUE 'LG003'
     SET MESSAGE_TEXT = 'ROOT logger cannot be deleted';
  END T_UNDELETABLE @

/**
 * Checks that the Ref_id for an appender is greater or equal to zero.
 */
CREATE OR REPLACE TRIGGER REF_ID_GREATER_EQUAL_ZERO
  BEFORE INSERT OR UPDATE ON LOGDATA.CONF_APPENDERS
  REFERENCING NEW AS N
  FOR EACH ROW
 WHEN (N.REF_ID < 0)
  T_REF_ID_ZERO: BEGIN
   SIGNAL SQLSTATE VALUE 'LG004'
     SET MESSAGE_TEXT = 'Ref_id for conf_appender should be greater or equal to zero';
  END T_REF_ID_ZERO @

/**
 * Checks that the appender_id for an appender is greater or equal to zero.
 */
CREATE OR REPLACE TRIGGER APPENDER_GREATER_EQUAL_ZERO
  BEFORE INSERT OR UPDATE ON LOGDATA.APPENDERS
  REFERENCING NEW AS N
  FOR EACH ROW
 WHEN (N.APPENDER_ID < 0)
  T_APPENDER_ID_ZERO: BEGIN
   SIGNAL SQLSTATE VALUE 'LG005'
     SET MESSAGE_TEXT = 'Appender_id for appenders should be greater or equal to zero';
  END T_APPENDER_ID_ZERO @