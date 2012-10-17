--#SET TERMINATOR @
SET CURRENT SCHEMA LOGGER_1A @

-- Table LOGDATA.LEVELS.

/**
 * Checks that the level are consecutives.
 */
CREATE OR REPLACE TRIGGER T1_LEVELS_CONS
  BEFORE INSERT ON LOGDATA.LEVELS
  REFERENCING NEW AS N
  FOR EACH ROW
 T_LEV_CON: BEGIN
  DECLARE MAX ANCHOR LOGDATA.LEVELS.LEVEL_ID;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'FLAG 8');

  SELECT MAX(LEVEL_ID) INTO MAX
    FROM LOGDATA.LEVELS;
  IF (N.LEVEL_ID < 0) THEN
   SIGNAL SQLSTATE VALUE 'LG0L1'
     SET MESSAGE_TEXT = 'LEVEL_ID should be equal or greater than zero';
  ELSEIF (N.LEVEL_ID <> MAX + 1) THEN
   SIGNAL SQLSTATE VALUE 'LG0L2'
     SET MESSAGE_TEXT = 'LEVEL_ID should be consecutive to the previous maximal value';
  END IF;
 END T_LEV_CON @

/**
 * Prevents the change of level_id.
 */
CREATE OR REPLACE TRIGGER T2_LEVELS_NO_UPD
  BEFORE UPDATE OF LEVEL_ID ON LOGDATA.LEVELS
  FOR EACH ROW
 SIGNAL SQLSTATE VALUE 'LG0L3'
   SET MESSAGE_TEXT = 'It is not possible to change the LEVEL_ID' @

/**
 * Allows to delete just the maximal LEVEL_ID value.
 */
CREATE OR REPLACE TRIGGER T3_LEVELS_DELETE
  BEFORE DELETE ON LOGDATA.LEVELS
  REFERENCING OLD AS O
  FOR EACH ROW
 T_LEV_DEL: BEGIN
  DECLARE MAX ANCHOR LOGDATA.LEVELS.LEVEL_ID;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'FLAG 9');

  SELECT MAX(LEVEL_ID) INTO MAX
    FROM LOGDATA.LEVELS;
  IF (O.LEVEL_ID = 0) THEN
   SIGNAL SQLSTATE VALUE 'LG0L4'
     SET MESSAGE_TEXT = 'Trying to delete the minimal value' ;
  ELSEIF (O.LEVEL_ID <> MAX) THEN
   SIGNAL SQLSTATE VALUE 'LG0L5'
     SET MESSAGE_TEXT = 'The only possible LEVEL_ID to delete is the maximal value' ;
  END IF;
 END T_LEV_DEL @

-- Table LOGDATA.CONF_LOGGERS.

/**
 * This trigger checks the insertion in the conf_logger table to see
 * if the logger_id already exists in the conf_logger_effective table. If not,
 * it retrieves the value from the sequence.
 */
CREATE OR REPLACE TRIGGER T1_CONF_LOGGERS_ID
  BEFORE UPDATE OR INSERT ON LOGDATA.CONF_LOGGERS
  REFERENCING NEW AS N
  FOR EACH ROW
 T_LOGGER_ID: BEGIN
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'FLAG 1');

  -- Checks that the only logger without parent is ROOT.
  IF (N.PARENT_ID IS NULL AND N.LOGGER_ID <> 0) THEN
    -- Raises an error.
    SIGNAL SQLSTATE VALUE 'LG0C1'
      SET MESSAGE_TEXT = 'The only logger without parent is ROOT';
  END IF;
  -- Prevents to insert a second logger.
  IF (N.LOGGER_ID = 0) THEN
   SELECT LOGGER_ID INTO LOGGER
     FROM LOGDATA.CONF_LOGGERS
     WHERE LOGGER_ID = 0;
   IF (LOGGER IS NOT NULL) THEN
     -- Raises an error.
     SIGNAL SQLSTATE VALUE 'LG0C3'
       SET MESSAGE_TEXT = 'There could be only one ROOT logger';
   END IF;
  END IF;
  -- Gets the loggerId and level from conf.
  SELECT LOGGER_ID INTO LOGGER
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE PARENT_ID = N.PARENT_ID;
  -- Checks if the loggedId exist in conf.
  IF (LOGGER IS NULL) THEN
   -- Gets the value from the sequence.
   SET N.LOGGER_ID = NEXT VALUE FOR LOGDATA.LOGGER_ID_SEQ;
  ELSE
   -- Gets the value from the configuration.
   SET N.LOGGER_ID = LOGGER;
  END IF;
 END T_LOGGER_ID @

/**
 * It restricts to update any value in CONF_LOGGERS different to LEVEL_ID.
 */
CREATE OR REPLACE TRIGGER T2_CONF_LOGGERS_NO_UPDATE
  BEFORE UPDATE OF LOGGER_ID, NAME, PARENT_ID ON LOGDATA.CONF_LOGGERS
  FOR EACH ROW
 SIGNAL SQLSTATE VALUE 'LG0C2'
   SET MESSAGE_TEXT = 'It is not possible to update any value in this table (only LEVEL_ID is possible)' @

/**
 * Activates updates in the effective table to synchronize the new
 * configuration.
 */
CREATE OR REPLACE TRIGGER T3_CONF_LOGGER_SYNC
  AFTER INSERT OR UPDATE OR DELETE ON LOGDATA.CONF_LOGGERS
  REFERENCING OLD AS O
  FOR EACH ROW
 T_SYNC_CONF: BEGIN

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'FLAG 2');

  -- It updates the same logger in the configuration, but with the trigger
  -- the descendancy is updated. The level_id provided is recalculated in the
  -- trigger, so the provided is a dummy.
  UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
    SET LEVEL_ID = 0
    WHERE LOGGER_ID = O.LOGGER_ID;
 END T_SYNC_CONF @

-- Table LOGDATA.CONF_LOGGERS_EFFECTIVE.

/**
 * Verifies that the parent is not null. The only logger with null parent is
 * root.
 */
CREATE OR REPLACE TRIGGER T1_EFFECTIVE_CHECK
  BEFORE INSERT OR UPDATE ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING NEW AS N
  FOR EACH ROW
 T_CHK_CONF_LOGGER_EFFECTIVE: BEGIN
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'FLAG 3');

  -- ParentId is null.
  IF (N.PARENT_ID IS NULL) THEN
   --  Checks if there is root logger defined with 0 as id.
   SELECT LOGGER_ID INTO LOGGER
     FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
     WHERE LOGGER_ID = 0;
   IF (N.LOGGER_ID <> 0 OR N.LOGGER_ID IS NULL) THEN
   -- The provided id is diff to zero or is null
    SIGNAL SQLSTATE VALUE 'LG0E1'
      SET MESSAGE_TEXT = 'The only logger without parent is ROOT';
   ELSEIF (LOGGER IS NOT NULL) THEN
    -- There is a ROOT logged already defined.
    SIGNAL SQLSTATE VALUE 'LG0E1'
      SET MESSAGE_TEXT = 'The only logger without parent is ROOT';
   END IF;
  END IF;
 END T_CHK_CONF_LOGGER_EFFECTIVE @

/**
 * Checks for duplicates.
 */
CREATE OR REPLACE TRIGGER T2_EFFECTIVE_NO_DUPLICATES
  BEFORE INSERT ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING NEW AS N
  FOR EACH ROW
 T_EFFECT_NO_DUP: BEGIN
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'FLAG 10 - ' || coalesce(N.LOGGER_ID,-1) || '-' || coalesce (N.PARENT_ID, -1) || '-' || coalesce (N.LEVEL_ID, -1));

  SELECT LOGGER_ID INTO LOGGER
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE NAME = N.NAME
    AND PARENT_ID = N.PARENT_ID;
  IF (LOGGER IS NOT NULL) THEN
     -- Raises an error.
     SIGNAL SQLSTATE VALUE 'LG0E5'
       SET MESSAGE_TEXT = 'Inserting a duplicate logger';
  END IF;
 END T_EFFECT_NO_DUP @

/**
 * Assigns the corresponding ID to the inserted logger.
 */
CREATE OR REPLACE TRIGGER T3_EFFECTIVE_INSERT
  BEFORE INSERT ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING NEW AS N
  FOR EACH ROW
 T_EFFECT_INSERT: BEGIN
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'FLAG 4 - ' || coalesce (N.LOGGER_ID, -1) || '-' || coalesce (N.PARENT_ID, -1) || '-' || coalesce (N.LEVEL_ID, -1));

  -- Gets the loggerId and level from conf.
  SELECT LOGGER_ID, LEVEL_ID INTO LOGGER, LEVEL
    FROM LOGDATA.CONF_LOGGERS
    WHERE PARENT_ID = N.PARENT_ID;
  -- Checks if the loggedId exist in conf.
  IF (LOGGER IS NULL) THEN
   -- Gets the value from the sequence.
   SET N.LOGGER_ID = NEXT VALUE FOR LOGDATA.LOGGER_ID_SEQ;
  ELSE
   -- Gets the value from the configuration.
   SET N.LOGGER_ID = LOGGER;
  END IF;
  -- Checks if the level has been established. Ignores the provided value.
  IF (LEVEL IS NULL) THEN
   -- Gets the value from an ascendency or default.
   SET N.LEVEL_ID = LOGADMIN.GET_DEFINED_PARENT_LOGGER(N.LOGGER_ID);
  ELSE
   -- Gets the value from the configuration. 
   SET N.LEVEL_ID = LEVEL;
  END IF;
 END T_EFFECT_INSERT @

/**
 * It restricts the update of any value in this table different to LEVEL_ID.
 */
CREATE OR REPLACE TRIGGER T4_EFFECTIVE_NO_UPDATE
  BEFORE UPDATE OF LOGGER_ID, NAME, PARENT_ID ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  FOR EACH ROW
 SIGNAL SQLSTATE VALUE 'LG0E2'
   SET MESSAGE_TEXT = 'It is not possible to update any value in this table (only LEVEL_ID is possible)' @

/**
 * This trigger validates the Logger level provided. When the configuration of
 * it was deleted in the conf table, it searched in the ascendency or default
 * value. If it was modified, it replaces the provided value with the correct
 * one.
 */
CREATE OR REPLACE TRIGGER T5_EFFECTIVE_LEVEL_UPDATE_DELETE
  BEFORE UPDATE OF LEVEL_ID ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING NEW AS N
  FOR EACH ROW
 T_UPDATE_DELETE: BEGIN
  DECLARE LEV_ID_CONF ANCHOR LOGDATA.LEVELS.LEVEL_ID;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'FLAG 5 - ' || coalesce (N.LEVEL_ID, -1));

  IF (N.LEVEL_ID IS NULL) THEN
   -- Trying to update the level by assinged a null level.
   SIGNAL SQLSTATE VALUE 'LG0E3'
     SET MESSAGE_TEXT = 'It is not possible to update the LEVEL_ID manually';
  END IF;
  -- Gets the configured level for the logger.
  SELECT LEVEL_ID INTO LEV_ID_CONF
    FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID = N.LOGGER_ID;
  IF (LEV_ID_CONF IS NULL) THEN
   -- There is not a defined level for this logger, it was deleted in conf.
   -- Gets the configured level from the closer ascendency or default value.
   SET N.LEVEL_ID = LOGADMIN.GET_DEFINED_PARENT_LOGGER(N.LOGGER_ID);
  ELSEIF (LEV_ID_CONF <> N.LEVEL_ID) THEN
   -- The provided value is not the same that in the configuration. Abort.
   -- Trying to update this value manually, with different value that the one
   -- established in CONF_LOGGERS.
   SIGNAL SQLSTATE VALUE 'LG0E3'
     SET MESSAGE_TEXT = 'It is not possible to update the LEVEL_ID manually';
  END IF;
 END T_UPDATE_DELETE @

/**
 * Updates the descendancy based on the configuration. If the conf was deleted
 * from the same logger, it is retrieved from the ascendency or default value,
 * in the BEFORE trigger for this table.
 */
CREATE OR REPLACE TRIGGER T6_EFFECTIVE_LEVEL_UPDATE
  AFTER UPDATE OF LEVEL_ID ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING NEW AS N
  FOR EACH ROW
 T_UPDATE_EFFEC: BEGIN

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'FLAG 6 - ' || coalesce (N.LEVEL_ID, -1));

  -- The provided level was verified in the previous trigger, thus
  -- update the descendency.
  CALL LOGADMIN.MODIFY_DESCENDANTS (N.LOGGER_ID, N.LEVEL_ID);
 END T_UPDATE_EFFEC @

/**
 * Verifies that the root logger is not deleted from the effective table. This
 * is the basic logger and it should always exist in this table.
 */
CREATE OR REPLACE TRIGGER T7_EFFECTIVE_ROOT_LOGGER_UNDELETABLE
  BEFORE DELETE ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING OLD AS O
  FOR EACH ROW
 WHEN (O.LOGGER_ID = 0)
  T_UNDELETABLE: BEGIN

   -- Debug
   -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'FLAG 7');

   SIGNAL SQLSTATE VALUE 'LG0E4'
     SET MESSAGE_TEXT = 'ROOT logger cannot be deleted';
  END T_UNDELETABLE @

/**
 * Updates the cache with the inserted/modified value.
 */
CREATE OR REPLACE TRIGGER T8_INSERT_CACHE
  AFTER INSERT OR UPDATE ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING NEW AS N
  FOR EACH ROW
 T_INSERT_CACHE: BEGIN
  -- Refresh the catalog.
  CALL LOGGER.SET_LOGGER_CACHE(N.LOGGER_ID, N.LEVEL_ID);
 END T_INSERT_CACHE @

/**
 * Deletes the value in the cache when the corresponding key/value is deleted
 * in the effective table.
 */
CREATE OR REPLACE TRIGGER T9_EFFECTIVE_DELETE_CACHE
  AFTER DELETE ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING OLD AS O
  FOR EACH ROW
 T_EFFECTIVE_DELETE_CACHE: BEGIN
  CALL LOGGER.SET_LOGGER_CACHE(O.LOGGER_ID, NULL);
 END T_EFFECTIVE_DELETE_CACHE @

-- Table LOGDATA.APPENDERS.

/**
 * Checks that the appender_id for an appender is greater or equal to zero.
 */
CREATE OR REPLACE TRIGGER T1_APPENDERS_GREATER_EQUAL_ZERO
  BEFORE INSERT OR UPDATE ON LOGDATA.APPENDERS
  REFERENCING NEW AS N
  FOR EACH ROW
 WHEN (N.APPENDER_ID < 0)
  T_APPENDER_ID_ZERO: BEGIN
   SIGNAL SQLSTATE VALUE 'LG0A1'
     SET MESSAGE_TEXT = 'APPENDER_ID for appenders should be greater or equal to zero';
  END T_APPENDER_ID_ZERO @

-- Table LOGDATA.CONF_APPENDERS.

/**
 * Removes the spaces around a pattern of an appender.
 */
CREATE OR REPLACE TRIGGER T1_CONF_APPENDERS_PATTERN
  BEFORE INSERT OR UPDATE ON LOGDATA.CONF_APPENDERS
  REFERENCING NEW AS N
  FOR EACH ROW
 T_CONF_APPENDERS_PATTERN: BEGIN
  SET N.PATTERN = TRIM(N.PATTERN);
 END T_CONF_APPENDERS_PATTERN @

-- Table LOGDATA.LOGS.

/**
 * Generates a unique date for the logs.
 */
CREATE OR REPLACE TRIGGER T1_LOGS_UNIQUE_DATE
  BEFORE INSERT ON LOGDATA.LOGS
  REFERENCING NEW AS N
  FOR EACH ROW
  SET N.DATE = GENERATE_UNIQUE() @