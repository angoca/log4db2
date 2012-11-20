--#SET TERMINATOR @
SET CURRENT SCHEMA LOGGER_1A @

-- Table LOGDATA.CONFIGURATION

/**
 * Cleans the cache or update it when the related configuration parameter is
 * modified.
 */
CREATE OR REPLACE TRIGGER T1_CONF_CACHE
  AFTER INSERT OR UPDATE ON LOGDATA.CONFIGURATION
  REFERENCING NEW AS N
  FOR EACH ROW
 T_CONF_CACHE: BEGIN
  DECLARE TMP ANCHOR LOGDATA.CONFIGURATION.VALUE;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 0');

  CASE N.KEY
   WHEN 'internalCache' THEN
    IF (N.VALUE = 'true') THEN
     CALL LOGGER.ACTIVATE_CACHE();
    ELSE
     CALL LOGGER.DEACTIVATE_CACHE();
    END IF;
   WHEN 'defaultRootLevel' THEN
    -- TODO UPDATE EFFECTIVE
   ELSE
    -- NOTHING.
  END CASE;
 END T_CONF_CACHE@

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
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 1');

  SELECT MAX(LEVEL_ID) INTO MAX
    FROM LOGDATA.LEVELS
    WITH UR;
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
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 2');

  SELECT MAX(LEVEL_ID) INTO MAX
    FROM LOGDATA.LEVELS
    WITH UR;
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
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 3');

  -- Checks that the only logger without parent is ROOT.
  IF (N.PARENT_ID IS NULL) THEN
   IF(N.LOGGER_ID <> 0) THEN
    -- Raises an error.
    SIGNAL SQLSTATE VALUE 'LG0C1'
      SET MESSAGE_TEXT = 'The only logger without parent is ROOT';
   ELSEIF (INSERTING) THEN
    SELECT LOGGER_ID INTO LOGGER
      FROM LOGDATA.CONF_LOGGERS
      WHERE LOGGER_ID = 0;
    IF (LOGGER IS NOT NULL) THEN
     -- Raises an error.
     SIGNAL SQLSTATE VALUE 'LG0C3'
       SET MESSAGE_TEXT = 'There could be only one ROOT logger';
    END IF;
   END IF;
  END IF;
  -- Prevents to insert a second logger.
  IF (INSERTING AND (N.LOGGER_ID <> 0 OR N.LOGGER_ID IS NULL)) THEN
   -- Gets the loggerId and level from effective.
   SELECT LOGGER_ID INTO LOGGER
     FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
     WHERE PARENT_ID = N.PARENT_ID
     AND NAME = N.NAME;
   -- Checks if the loggedId exist in effective.
   IF (LOGGER IS NULL) THEN
    -- Gets the value from the sequence.
    SET N.LOGGER_ID = NEXT VALUE FOR LOGDATA.LOGGER_ID_SEQ;
   ELSE
    -- Gets the value from the effective table.
    SET N.LOGGER_ID = LOGGER;
   END IF;
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
  AFTER INSERT OR UPDATE
  ON LOGDATA.CONF_LOGGERS
  REFERENCING OLD AS O NEW AS N
  FOR EACH ROW
 T_SYNC_CONF: BEGIN
  DECLARE LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 4 ' || COALESCE(N.LOGGER_ID, -1) || '=' || COALESCE(N.LEVEL_ID, -1) || '<>' || COALESCE(O.LEVEL_ID, -1));

  -- It updates the same logger in the configuration, but with the trigger
  -- the descendancy is updated.
  IF (N.LEVEL_ID IS NOT NULL) THEN
   SET LEVEL = N.LEVEL_ID;
  ELSE
   SET LEVEL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(N.LOGGER_ID);
  END IF;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 4.1 ' || COALESCE(N.LOGGER_ID, -1) || '<>' ||COALESCE(LEVEL, -1));

  UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
    SET LEVEL_ID = LEVEL
    WHERE LOGGER_ID = N.LOGGER_ID;
 END T_SYNC_CONF @

/**
 * Activates updates in the effective table to synchronize the new
 * configuration.
 */
CREATE OR REPLACE TRIGGER T4_CONF_LOGGER_SYNC_DELETE
  BEFORE DELETE 
  ON LOGDATA.CONF_LOGGERS
  REFERENCING OLD AS O NEW AS N
  FOR EACH ROW
 T_SYNC_CONF_DEL: BEGIN
  DECLARE LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 4 ' || COALESCE(O.LOGGER_ID,-1) || '=' || COALESCE(O.LEVEL_ID,-1));

--  SET LEVEL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(O.LOGGER_ID);

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 4.1 ' || COALESCE(O.LOGGER_ID,-1) || '<>' ||COALESCE(LEVEL,-1));

  -- Puts the level to update in cascade. Very IO expensive.
--  UPDATE LOGDATA.CONF_LOGGERS
--    SET LEVEL_ID = LEVEL
--    WHERE LOGGER_ID = O.LOGGER_ID;
 END T_SYNC_CONF_DEL @

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
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 5 =' || coalesce(N.LOGGER_ID,-1));

  -- ParentId is null.
  IF (N.PARENT_ID IS NULL) THEN
   --  Gets the root logger defined with 0 as id.
   SELECT LOGGER_ID INTO LOGGER
     FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
     WHERE LOGGER_ID = 0
     WITH UR;
   IF (N.LOGGER_ID <> 0 OR N.LOGGER_ID IS NULL) THEN
   -- The provided id is diff to zero or is null
    SIGNAL SQLSTATE VALUE 'LGAE1'
      SET MESSAGE_TEXT = 'The only logger without parent is ROOT';
   ELSEIF (INSERTING AND LOGGER IS NOT NULL) THEN
    -- There is a ROOT logged already defined.
    SIGNAL SQLSTATE VALUE 'LGBE1'
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
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 6 - ' || coalesce(N.LOGGER_ID,-1) || '-' || coalesce (N.PARENT_ID, -1) || '-' || coalesce (N.LEVEL_ID, -1));

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
  -- Handles the limit cascade call.
  DECLARE EXIT HANDLER FOR SQLSTATE '54038'
   BEGIN
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES 
    (2, 'LG001. Cascade call limit achieve, for T3_EFFECTIVE_INSERT: ' || COALESCE(N.LOGGER_ID, -1) || '~' || COALESCE(N.NAME, 'null'));
    RESIGNAL SQLSTATE 'LG001';
   END;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 7 - ' || coalesce (N.LOGGER_ID, -1) || '-' || coalesce (N.PARENT_ID, -1) || '-' || coalesce (N.LEVEL_ID, -1));

  -- Gets the loggerId and level from conf.
  SELECT LOGGER_ID, LEVEL_ID INTO LOGGER, LEVEL
    FROM LOGDATA.CONF_LOGGERS
    WHERE PARENT_ID = N.PARENT_ID
    AND NAME = N.NAME
    WITH UR;
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

   -- Debug
   -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 8 - ' || coalesce (N.LOGGER_ID, -1));

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
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 9 - ' || coalesce (N.LEVEL_ID, -1));

  IF (N.LEVEL_ID IS NULL) THEN
   -- Trying to update the level by assinged a null level.
   SIGNAL SQLSTATE VALUE 'LGAE3'
     SET MESSAGE_TEXT = 'It is not possible to update the LEVEL_ID manually';
  END IF;
  -- Gets the configured level for the logger.
  SELECT LEVEL_ID INTO LEV_ID_CONF
    FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID = N.LOGGER_ID
    WITH UR;
  IF (LEV_ID_CONF IS NULL AND N.LOGGER_ID IS NOT NULL) THEN
   -- There is not a defined level for this logger, it was probably deleted in
   -- conf or this logger has never been configured.
   -- Gets the configured level from the closer ascendency or default value.
   SET N.LEVEL_ID = LOGADMIN.GET_DEFINED_PARENT_LOGGER(N.LOGGER_ID);
  ELSEIF (LEV_ID_CONF <> N.LEVEL_ID) THEN
   -- The provided value is not the same that in the configuration. Abort.
   -- Trying to update this value manually, with different value that the one
   -- established in CONF_LOGGERS.
   SIGNAL SQLSTATE VALUE 'LGBE3'
     SET MESSAGE_TEXT = 'It is not possible to update the LEVEL_ID manually';
  ELSEIF (N.LOGGER_ID IS NULL) THEN
   SIGNAL SQLSTATE VALUE 'PAILA'
     SET MESSAGE_TEXT = 'LOGGER_ID IS NULL - TODO';
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
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 11 = ' || coalesce (N.LOGGER_ID, -1) || '=' || coalesce (N.LEVEL_ID, -1));

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
   -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 12');

   SIGNAL SQLSTATE VALUE 'LG0E4'
     SET MESSAGE_TEXT = 'ROOT logger cannot be deleted';
  END T_UNDELETABLE @

/**
 * Deletes the value in the cache when the corresponding key/value is deleted
 * in the effective table.
 */
CREATE OR REPLACE TRIGGER T8_EFFECTIVE_DELETE_CACHE
  AFTER DELETE ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING OLD AS O
  FOR EACH ROW
 T_EFFECTIVE_DELETE_CACHE: BEGIN
  CALL LOGGER.DELETE_LOGGER_CACHE(O.LOGGER_ID);
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

/**
 * Refreshes the value of root logger in Effective table. The value is
 * recalculated according the configuration (conf_loggers table or
 * default value from configuration table).
 * /
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LEVEL_ID = 3
  WHERE LOGGER_ID = 0@*/
