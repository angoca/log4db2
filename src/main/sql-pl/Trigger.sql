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

SET CURRENT SCHEMA LOGGER_1B @

/**
 * Defines the triggers for the different tables. The creation order is important
 * to validate something before other thing.
 *
 * Version: 2014-02-14 1-Alpha
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

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
   WHEN 'defaultRootLevelId' THEN
    BEGIN
     DECLARE EXIST SMALLINT DEFAULT 0;
     DECLARE VALUE ANCHOR LOGDATA.LEVELS.LEVEL_ID;

     -- FIXME it does not work correctly when it should not update.
     SELECT 1 INTO EXIST
       FROM LOGDATA.CONF_LOGGERS
       WHERE LOGGER_ID = 0;
     -- Checks if root logger is defined.
     IF (EXIST <> 1) THEN

      -- Writes a message to indicate that is necessary to update the table
      -- manually. If this is automatic, there is an error, because this
      -- trigger is active when the configuration is modified, and the trigger
      -- actives another one (T5) when update the table; this last does not
      -- take into account the given value, but looks for the it in the
      -- configuration (GET_DEFINED_PARENT_LOGGER > GET_DEFAULT_LEVEL >
      -- GET_VALUE > REFRESH_CONF), and this creates a SQL0746, because the
      -- table is being modified and queried at the same time.
      INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE)
        VALUES (5, -1, 'A manual CONF_LOGGERS_EFFECTIVE update should be realized.');

      -- There is nothing in conf_loggers, thus update conf_loggers_effective.
      -- FIXME when uncommented, there is an error when trying to change the
      -- configuration value
      -- UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
      --   SET LEVEL_ID = SMALLINT(N.VALUE)
      --   WHERE LOGGER_ID = 0;
     END IF;
    END;
   ELSE
    -- NOTHING.
  END CASE;
 END T_CONF_CACHE @

COMMENT ON TRIGGER T1_CONF_CACHE IS
  'Cleans the cache or update it when the related configuration parameter is modified'@

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

COMMENT ON TRIGGER T1_LEVELS_CONS IS 'Checks that the level are consecutives'@

/**
 * Prevents the change of level_id.
 */
CREATE OR REPLACE TRIGGER T2_LEVELS_NO_UPD
  BEFORE UPDATE OF LEVEL_ID ON LOGDATA.LEVELS
  FOR EACH ROW
 SIGNAL SQLSTATE VALUE 'LG0L3'
   SET MESSAGE_TEXT = 'It is not possible to change the LEVEL_ID' @

COMMENT ON TRIGGER T2_LEVELS_NO_UPD IS 'Prevents the change of level_id'@

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

COMMENT ON TRIGGER T3_LEVELS_DELETE IS 'Allows to delete just the maximal LEVEL_ID value'@

-- Table LOGDATA.CONF_LOGGERS.

/**
 * This trigger checks the insertion or updating in the conf_logger table to see
 * if the logger_id already exists or retrieve from the sequence.
 */
CREATE OR REPLACE TRIGGER T1_CONF_LOGGERS_ID
  BEFORE UPDATE OR INSERT ON LOGDATA.CONF_LOGGERS
  REFERENCING OLD AS O NEW AS N
  FOR EACH ROW
 T_LOGGER_ID: BEGIN
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 3');

  -- Checks that ROOT is not being inserted.
  IF (INSERTING AND N.LOGGER_ID = 0) THEN
   SIGNAL SQLSTATE VALUE 'LG0C1'
     SET MESSAGE_TEXT = 'ROOT cannot be inserted';
  ELSEIF (N.LOGGER_ID > 0) THEN
   -- Checks that the only logger without parent is ROOT.
   IF (N.PARENT_ID IS NULL) THEN
    -- Raises an error.
    SIGNAL SQLSTATE VALUE 'LG0C1'
      SET MESSAGE_TEXT = 'The only logger without parent is ROOT';
   END IF;
  ELSEIF (N.LOGGER_ID < 0) THEN
   SIGNAL SQLSTATE VALUE  'LG0C3'
     SET MESSAGE_TEXT = 'LOGGER_ID cannot be negative';
  END IF;
 END T_LOGGER_ID @

COMMENT ON TRIGGER T1_CONF_LOGGERS_ID IS 'This trigger checks the insertion in the conf_logger table'@

/**
 * It restricts to update any value in CONF_LOGGERS different to LEVEL_ID.
 */
CREATE OR REPLACE TRIGGER T2_CONF_LOGGERS_NO_UPDATE
  BEFORE UPDATE OF LOGGER_ID, NAME, PARENT_ID ON LOGDATA.CONF_LOGGERS
  FOR EACH ROW
 SIGNAL SQLSTATE VALUE 'LG0C2'
   SET MESSAGE_TEXT = 'It is not possible to update any value in this table (only LEVEL_ID is possible)' @

COMMENT ON TRIGGER T2_CONF_LOGGERS_NO_UPDATE IS 'It restricts to update any value in CONF_LOGGERS different to LEVEL_ID'@

/**
 * Delete all sons and the correponding row in effective table.
 */
CREATE OR REPLACE TRIGGER T3_CONF_LOGGER_SYNC_DELETE
  BEFORE DELETE 
  ON LOGDATA.CONF_LOGGERS
  REFERENCING OLD AS O
  FOR EACH ROW
 T_SYNC_CONF_DEL: BEGIN
  DECLARE LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID;
  DECLARE SON_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE AT_END BOOLEAN DEFAULT FALSE;
  DECLARE SONS CURSOR FOR
    SELECT LOGGER_ID
    FROM LOGDATA.CONF_LOGGERS
    WHERE PARENT_ID = O.LOGGER_ID;
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET AT_END = TRUE;

  -- Delete all sons.
  OPEN SONS;
  FETCH SONS INTO SON_ID;
  WHILE (AT_END = FALSE) DO
   DELETE LOGDATA.CONF_LOGGERS
     WHERE LOGGER_ID = SON_ID;
  END WHILE;
  -- Delete the corresponding row in effective table.
  DELETE LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE LOGGER_ID = O.LOGGER_ID;
 END T_SYNC_CONF_DEL @

COMMENT ON TRIGGER T3_CONF_LOGGER_SYNC_DELETE IS 'Delete all sons and the corresponding row in effective table'@

/**
 * Activates updates in the effective table to synchronize the new
 * configuration.
 */
CREATE OR REPLACE TRIGGER T4_CONF_LOGGER_SYNC
  AFTER INSERT OR UPDATE
  ON LOGDATA.CONF_LOGGERS
  REFERENCING OLD AS O NEW AS N
  FOR EACH ROW
 T_SYNC_CONF: BEGIN
  DECLARE LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID;
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) 
  --   VALUES (5, -1, 'tFLAG 4 ' || COALESCE(N.LOGGER_ID, -1) || '='
  --   || COALESCE(N.LEVEL_ID, -1) || '<>' || COALESCE(O.LEVEL_ID, -1));

  -- It updates the same logger in the configuration, but with the trigger
  -- the descendancy is updated.
  IF (N.LEVEL_ID IS NOT NULL) THEN
   SET LEVEL = N.LEVEL_ID;
  ELSE
   SET LEVEL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(N.LOGGER_ID);
  END IF;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'tFLAG 4.1 '
  --   || COALESCE(N.LOGGER_ID, -1) || '<>' ||COALESCE(LEVEL, -1));

  -- TODO It should update the descendancy.
  UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
    SET LEVEL_ID = LEVEL
    WHERE LOGGER_ID = N.LOGGER_ID;
 END T_SYNC_CONF @

COMMENT ON TRIGGER T4_CONF_LOGGER_SYNC IS 'Activates updates in the effective table to synchronize the new configuration'@

/**
 * Refreshes the loggers cache after any modification.
 */
CREATE OR REPLACE TRIGGER T5_CONF_LOGGER_CLEAN_CACHE
  AFTER INSERT OR UPDATE OR DELETE 
  ON LOGDATA.CONF_LOGGERS
  FOR EACH ROW
 T_SYNC_CONF_CLN_CACHE: BEGIN
  CALL LOGGER.DELETE_ALL_LOGGER_CACHE();
 END T_SYNC_CONF_CLN_CACHE @

COMMENT ON TRIGGER T5_CONF_LOGGER_CLEAN_CACHE IS 'Refreshes the loggers cache after any modification'@

-- Table LOGDATA.CONF_LOGGERS_EFFECTIVE.

/**
 *  Assigns the LEVEL_ID.
 */
CREATE OR REPLACE TRIGGER T1_EFFECTIVE_LEVEL_ID
  BEFORE INSERT --OF LEVEL_ID
  ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING NEW AS N
  FOR EACH ROW
 T_EFFECT_LEVEL_ID: BEGIN
  -- Assigns the inherited level. It cannot be assinged by the insert/update.
  SET N.LEVEL_ID = LOGADMIN.GET_DEFINED_PARENT_LOGGER(N.LOGGER_ID);
 END T_EFFECT_LEVEL_ID @
 
--COMMENT ON TRIGGER T1_EFFECTIVE_LEVEL_ID IS 'Assigns the LEVEL_ID';

/**
 * It restricts the update of any value in this table different to LEVEL_ID.
 */
CREATE OR REPLACE TRIGGER T2_EFFECTIVE_NO_UPDATE
  BEFORE UPDATE OF LOGGER_ID, HIERARCHY ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  FOR EACH ROW
 SIGNAL SQLSTATE VALUE 'LG0E2'
   SET MESSAGE_TEXT = 'It is not possible to update any value in this table (only LEVEL_ID is possible)' @

COMMENT ON TRIGGER T2_EFFECTIVE_NO_UPDATE IS 'It restricts the update of any value in this table different to LEVEL_ID'@

/**
 * Updates the descendancy based on the configuration. If the conf was deleted
 * from the same logger, it is retrieved from the ascendency or default value,
 * in the BEFORE trigger for this table.
 */
CREATE OR REPLACE TRIGGER T3_EFFECTIVE_LEVEL_UPDATE
  AFTER UPDATE OF LEVEL_ID ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING NEW AS N
  FOR EACH ROW
 T_UPDATE_EFFEC: BEGIN

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE)
  --   VALUES (5, -1, 'tFLAG 11 = ' || coalesce (N.LOGGER_ID, -1) || '='
  -- || coalesce (N.LEVEL_ID, -1));

  -- The provided level was verified in the previous trigger, thus
  -- update the descendency.
  CALL LOGADMIN.MODIFY_DESCENDANTS (N.LOGGER_ID, N.LEVEL_ID);
 END T_UPDATE_EFFEC @

COMMENT ON TRIGGER T3_EFFECTIVE_LEVEL_UPDATE IS
  'Updates the descendancy based on the configuration.
If the conf was deleted from the same logger, it is retrieved from the
ascendency or default value, in the BEFORE trigger for this table'@

/**
 * Verifies that the root logger is not deleted from the effective table. This
 * is the basic logger and it should always exist in this table.
 */
CREATE OR REPLACE TRIGGER T4_EFFECTIVE_ROOT_LOGGER_UNDELETABLE
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

COMMENT ON TRIGGER T4_EFFECTIVE_ROOT_LOGGER_UNDELETABLE IS
  'Verifies that the root logger is not deleted from the effective table.
This is the basic logger and it should always exist in this table.'@

  -- TODO Delete this method CALL LOGGER.DELETE_LOGGER_CACHE(O.LOGGER_ID);

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

COMMENT ON TRIGGER T1_APPENDERS_GREATER_EQUAL_ZERO IS
  'Checks that the appender_id for an appender is greater or equal to zero'@

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

COMMENT ON TRIGGER T1_CONF_APPENDERS_PATTERN IS 'Removes the spaces around a pattern of an appender'@

-- Table LOGDATA.LOGS.

/**
 * Generates a unique date for the logs.
 */
CREATE OR REPLACE TRIGGER T1_LOGS_UNIQUE_DATE
  BEFORE INSERT ON LOGDATA.LOGS
  REFERENCING NEW AS N
  FOR EACH ROW
  -- TODO Test if this cqll is expensive.
  SET N.DATE = GENERATE_UNIQUE() @

COMMENT ON TRIGGER T1_LOGS_UNIQUE_DATE IS 'Generates a unique date for the logs'@

