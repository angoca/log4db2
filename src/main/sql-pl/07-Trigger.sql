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

SET CURRENT SCHEMA LOGGER_1RC @

/**
 * Defines the triggers for the different tables. The creation order is
 * important to validate something before other thing.
 *
 * Version: 2014-02-14 1-RC
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

-- Table LOGDATA.CONFIGURATION

/**
 * Cleans the cache or update it when the related configuration parameter is
 * modified.
 *
 * TESTS
 *   TestConfiguration: Validates if this error is thrown.
 *   TestsMessages: Checks the output of the error.
 */
CREATE OR REPLACE TRIGGER T1_CNF_CCHE
  AFTER INSERT OR UPDATE ON LOGDATA.CONFIGURATION
  REFERENCING NEW AS N
  FOR EACH ROW
 T1_CNF_CCHE: BEGIN
  DECLARE TMP ANCHOR LOGDATA.CONFIGURATION.VALUE;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1,
  --  '> T1_CNF_CCHE - ' || COALESCE(N.KEY, 'null'));

  CASE N.KEY
   WHEN 'internalCache' THEN
    IF (N.VALUE = 'true') THEN
     CALL LOGGER.ACTIVATE_CACHE();
    ELSE
     CALL LOGGER.DEACTIVATE_CACHE();
    END IF;
   WHEN 'defaultRootLevelId' THEN
    BEGIN
     DECLARE LVL ANCHOR LOGDATA.CONF_LOGGERS.LEVEL_ID;
     DECLARE INVALID_CAST CONDITION FOR SQLSTATE '22018';
     DECLARE EXIT HANDLER FOR INVALID_CAST
       RESIGNAL SQLSTATE 'LG0T1'
       SET MESSAGE_TEXT = 'Invalid value for defaultRootLevelId';

     -- Tests if the given value can be converted to smallint.
     SET LVL = SMALLINT(N.VALUE);

     SELECT LEVEL_ID INTO LVL
       FROM LOGDATA.CONF_LOGGERS
       WHERE LOGGER_ID = 0
       FETCH FIRST 1 ROW ONLY
       WITH UR;
     -- Checks if root logger is defined.
     IF (LVL IS NULL) THEN
      SET LVL = SMALLINT(N.VALUE);

      -- Debug
      -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1,
      --  'T1_CNF_CCHE - Update to ' || COALESCE(N.VALUE, 'null'));

      -- Writes a message to indicate that is necessary to update the table
      -- manually. If this is automatic, there is an error, because this
      -- trigger is activated when the configuration is modified, and the trigger
      -- actives another one (T1_EFF_LVL_ID) when update the table; this last
      -- does not take into account the given value, but looks for the it in the
      -- configuration (GET_DEFINED_PARENT_LOGGER > GET_DEFAULT_LEVEL >
      -- GET_VALUE > REFRESH_CONF), and this creates a SQL0746, because the
      -- table is being modified and queried at the same time.
      INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE)
        VALUES (4, -1, 'A manual CONF_LOGGERS_EFFECTIVE update should be realized.');

      -- Conf_loggers is not defined, thus update conf_loggers_effective.
      -- FIXME
      -- UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
      --  SET LEVEL_ID = LVL
      --  WHERE LOGGER_ID = 0;
     END IF;
    END;
   ELSE
    -- NOTHING.
  END CASE;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, '< T1_CNF_CCHE');
 END T1_CNF_CCHE @

COMMENT ON TRIGGER T1_CNF_CCHE IS
  'Cleans the cache or update it when the related configuration parameter is modified'@

-- Table LOGDATA.LEVELS.

/**
 * Checks that the level are consecutive.
 *
 * TESTS
 *   TestsLevels: Validates if the errors are thrown.
 *   TestsMessages: Checks the output of the error.
 */
CREATE OR REPLACE TRIGGER T1_LVL_CON
  BEFORE INSERT ON LOGDATA.LEVELS
  REFERENCING NEW AS N
  FOR EACH ROW
 T1_LVL_CON: BEGIN
  DECLARE MAX ANCHOR LOGDATA.LEVELS.LEVEL_ID;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'FLAG 1 - T1_LVL_CON');

  SELECT MAX(LEVEL_ID) INTO MAX
    FROM LOGDATA.LEVELS
    FETCH FIRST 1 ROW ONLY
    WITH CS;
  IF (N.LEVEL_ID < 0) THEN
   SIGNAL SQLSTATE VALUE 'LG0L1'
     SET MESSAGE_TEXT = 'LEVEL_ID should be equal or greater than zero';
  ELSEIF (N.LEVEL_ID <> MAX + 1) THEN
   SIGNAL SQLSTATE VALUE 'LG0L2'
     SET MESSAGE_TEXT = 'LEVEL_ID should be consecutive to the previous maximal value';
  END IF;
 END T1_LVL_CON @

COMMENT ON TRIGGER T1_LVL_CON IS 'Checks that the level are consecutives'@

/**
 * Prevents the change of level_id.
 */
CREATE OR REPLACE TRIGGER T2_LVL_NO_UPD
  BEFORE UPDATE OF LEVEL_ID ON LOGDATA.LEVELS
  FOR EACH ROW
 SIGNAL SQLSTATE VALUE 'LG0L3'
   SET MESSAGE_TEXT = 'It is not possible to change the LEVEL_ID' @

COMMENT ON TRIGGER T2_LVL_NO_UPD IS 'Prevents the change of level_id'@

/**
 * Allows to delete just the maximal LEVEL_ID value.
 * TESTS
 *   TestsMessages: Checks the output of the error.
 */
CREATE OR REPLACE TRIGGER T3_LVL_DEL
  BEFORE DELETE ON LOGDATA.LEVELS
  REFERENCING OLD AS O
  FOR EACH ROW
 T3_LVL_DEL: BEGIN
  DECLARE MAX ANCHOR LOGDATA.LEVELS.LEVEL_ID;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, 'FLAG 2 - T3_LVL_DEL');

  SELECT MAX(LEVEL_ID) INTO MAX
    FROM LOGDATA.LEVELS
    FETCH FIRST 1 ROW ONLY
    WITH CS;
  IF (O.LEVEL_ID = 0) THEN
   SIGNAL SQLSTATE VALUE 'LG0L4'
     SET MESSAGE_TEXT = 'Trying to delete the minimal value' ;
  ELSEIF (O.LEVEL_ID <> MAX) THEN
   SIGNAL SQLSTATE VALUE 'LG0L5'
     SET MESSAGE_TEXT = 'The only possible LEVEL_ID to delete is the maximal value' ;
  END IF;
 END T3_LVL_DEL @

COMMENT ON TRIGGER T3_LVL_DEL IS 'Allows to delete just the maximal LEVEL_ID value'@

-- Table LOGDATA.CONF_LOGGERS.

/**
 * This trigger checks the insertion or updating in the conf_loggers table to see
 * if the logger_id already exists or retrieve from the sequence.
 *
 * TESTS
 *   TestConfLoggers: Verifies if the different errors are thrown.
 *   TestsMessages: Checks the output of the error.
 */
CREATE OR REPLACE TRIGGER T1_CNFLGR_ID
  BEFORE UPDATE OR INSERT ON LOGDATA.CONF_LOGGERS
  REFERENCING OLD AS O NEW AS N
  FOR EACH ROW
 T1_CNFLGR_ID: BEGIN
  DECLARE LOGGER ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE EXISTING ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, '><T1_CNFLGR_ID');

  -- Checks that ROOT is not being inserted.
  IF (INSERTING AND N.LOGGER_ID = 0) THEN
   SIGNAL SQLSTATE VALUE 'LG0C1'
     SET MESSAGE_TEXT = 'ROOT cannot be inserted';
  -- Checks that the only logger without parent is ROOT.
  ELSEIF (N.LOGGER_ID > 0 AND N.PARENT_ID IS NULL) THEN
   -- Raises an error.
   SIGNAL SQLSTATE VALUE 'LG0C2'
     SET MESSAGE_TEXT = 'The only logger without parent is ROOT';
  -- LOGGER_ID cannot be negative.
  ELSEIF (N.LOGGER_ID < 0) THEN
   SIGNAL SQLSTATE VALUE  'LG0C3'
     SET MESSAGE_TEXT = 'LOGGER_ID cannot be negative';
  ELSEIF (N.LOGGER_ID = N.PARENT_ID) THEN
   SIGNAL SQLSTATE VALUE  'LG0C5'
     SET MESSAGE_TEXT = 'The parent cannot be itself';
  END IF;
  SELECT LOGGER_ID INTO EXISTING
    FROM LOGDATA.CONF_LOGGERS
    WHERE PARENT_ID = N.PARENT_ID
    AND NAME = N.NAME
    FETCH FIRST 1 ROW ONLY;
  IF (INSERTING AND EXISTING IS NOT NULL) THEN
   SIGNAL SQLSTATE VALUE  'LG0C6'
     SET MESSAGE_TEXT = 'The same son already exist in the database';
  END IF;
 END T1_CNFLGR_ID @

COMMENT ON TRIGGER T1_CNFLGR_ID IS 'This trigger checks the insertion or updating in the conf_logger table'@

/**
 * It restricts to update any value in CONF_LOGGERS different to LEVEL_ID.
 *
 * TESTS
 *   TestConfLoggers verifies if the different errors are thrown.
 *   TestsMessages: Checks the output of the error.
 */
CREATE OR REPLACE TRIGGER T2_CNFLGR_NO_UPD
  BEFORE UPDATE OF LOGGER_ID, NAME, PARENT_ID ON LOGDATA.CONF_LOGGERS
  FOR EACH ROW
 SIGNAL SQLSTATE VALUE 'LG0C4'
   SET MESSAGE_TEXT = 'The LEVEL_ID is the only column that can be updated' @

COMMENT ON TRIGGER T2_CNFLGR_NO_UPD IS 'It restricts to update any value in CONF_LOGGERS different to LEVEL_ID'@

/**
 * Inserts or updates in the effective table to synchronize the new
 * configuration.
 */
CREATE OR REPLACE TRIGGER T3_CNFLGR_SYN
  AFTER INSERT OR UPDATE
  ON LOGDATA.CONF_LOGGERS
  REFERENCING OLD AS O NEW AS N
  FOR EACH ROW
 T3_CNFLGR_SYN: BEGIN
  DECLARE LEVEL ANCHOR LOGDATA.CONF_LOGGERS.LEVEL_ID;
  DECLARE QTY SMALLINT DEFAULT 0;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE)
  --   VALUES (5, -1, '>T3_CNFLGR_SYN logger ' || COALESCE(N.LOGGER_ID, -1)
  --   || ',level ' || COALESCE(N.LEVEL_ID, -1) || '<>'
  --   || COALESCE(O.LEVEL_ID, -1) || ',name ' || COALESCE(N.NAME, 'null'));

  IF (N.LEVEL_ID IS NULL) THEN
   SET LEVEL = 0;
  END IF;

  -- Inserting is done in GET_LOGGER
  IF (UPDATING) THEN
   -- If updating and exists in effective, then update
   SELECT COUNT(1) INTO QTY
     FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
     WHERE LOGGER_ID = N.LOGGER_ID
     FETCH FIRST 1 ROW ONLY
     WITH UR;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE)
  --   VALUES (5, -1, ' T3_CNFLGR_SYN qty_sync ' || QTY);

   IF (QTY > 0) THEN
    UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
    -- LEVEL_ID could be null, thus we update with an always existent level.
      SET LEVEL_ID = 0
      WHERE LOGGER_ID = N.LOGGER_ID;
   END IF;
  END IF;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE)
  --   VALUES (5, -1, '<T3_CNFLGR_SYN');
 END T3_CNFLGR_SYN @

COMMENT ON TRIGGER T3_CNFLGR_SYN IS 'Inserts or updates in the effective table to synchronize the new configuration'@

-- Table LOGDATA.CONF_LOGGERS_EFFECTIVE.

/**
 * Assigns the LEVEL_ID.
 */
CREATE OR REPLACE TRIGGER T1_EFF_LVL_ID
  BEFORE INSERT OR UPDATE OF LEVEL_ID
  ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING NEW AS N
  FOR EACH ROW
 T1_EFF_LVL_ID: BEGIN
  DECLARE NESTED_LIMIT_ACHIEVED CONDITION FOR SQLSTATE '54038';
  DECLARE EXIT HANDLER FOR NESTED_LIMIT_ACHIEVED
    BEGIN
     CALL LOGGER.LOG_TABLES(-1, 0, 'Limit nested limit arrived '
       || N.LOGGER_ID);
    RESIGNAL;
   END;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE)
  --   VALUES (5, -1, '>T1_EFF_LVL_ID logger ' || COALESCE (N.LOGGER_ID, -1)
  --   || ',level ' || COALESCE (N.LEVEL_ID, -1));

  SELECT LEVEL_ID INTO N.LEVEL_ID
    FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID = N.LOGGER_ID
    FETCH FIRST 1 ROW ONLY
    WITH CS;
  -- Assigns the inherited level. It cannot be assigned by the insert/update.
  IF (N.LEVEL_ID IS NULL) THEN

   -- Debug
   -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE)
   --   VALUES (5, -1, ' T1_EFF_LVL_ID null level');

   SET N.LEVEL_ID = LOGGER.GET_DEFINED_PARENT_LOGGER(N.LOGGER_ID);
  END IF;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE)
  --   VALUES (5, -1, '<T1_EFF_LVL_ID logger ' || COALESCE (N.LOGGER_ID, -1)
  --   || ',level ' || COALESCE (N.LEVEL_ID, -1));

 END T1_EFF_LVL_ID @

COMMENT ON TRIGGER T1_EFF_LVL_ID IS 'Assigns the LEVEL_ID' @

/**
 * It restricts the update of any value in this table different to LEVEL_ID.
 *
 * TESTS
 *   TestConfLoggersEffective: Verifies if the different errors are thrown.
 *   TestsMessages: Checks the output of the error.
 */
CREATE OR REPLACE TRIGGER T2_EFF_NO_UPD
  BEFORE UPDATE OF LOGGER_ID, HIERARCHY ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  FOR EACH ROW
 SIGNAL SQLSTATE VALUE 'LG0E1'
   SET MESSAGE_TEXT = 'The LEVEL_ID is the only column that can be updated' @

COMMENT ON TRIGGER T2_EFF_NO_UPD IS 'It restricts the update of any value in this table different to LEVEL_ID'@

/**
 * Updates the descendants based on the configuration. If the conf was deleted
 * from the same logger, it is retrieved from the ascendency or default value,
 * in the BEFORE trigger for this table.
 */
CREATE OR REPLACE TRIGGER T3_EFF_LVL_UPD
  AFTER UPDATE OF LEVEL_ID ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING NEW AS N
  FOR EACH ROW
 T3_EFF_LVL_UPD: BEGIN

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE)
  --   VALUES (5, -1, '>T3_EFF_LVL_UPD logger ' || COALESCE (N.LOGGER_ID, -1)
  --   || ',level ' || COALESCE (N.LEVEL_ID, -1));

   IF (LOGGER.LOCK_MODIFY_DESCENDANTS IS NULL) THEN
    SET LOGGER.LOCK_MODIFY_DESCENDANTS = LOGGER.VAL_TRUE;

    -- The provided level was verified in the previous trigger, thus
    -- update the descendants.
    CALL LOGGER.MODIFY_DESCENDANTS (N.LOGGER_ID, N.LEVEL_ID);

    SET LOGGER.LOCK_MODIFY_DESCENDANTS = NULL;
   ELSE

    -- Debug
    -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE)
    --   VALUES (5, -1, ' T3_EFF_LVL_UPD No modif');

   END IF;

  -- Debug
  -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE)
  --   VALUES (5, -1, '<T3_EFF_LVL_UPD ' || COALESCE (N.LOGGER_ID, -1));
 END T3_EFF_LVL_UPD @

COMMENT ON TRIGGER T3_EFF_LVL_UPD IS
  'Updates the descendancy based on the configuration.
If the conf was deleted from the same logger, it is retrieved from the
ascendency or default value, in the BEFORE trigger for this table'@

/**
 * Verifies that the root logger is not deleted from the effective table. This
 * is the basic logger and it should always exist in this table.
 *
 * TESTS
 *   TestConfLoggersDelete and TestConfLoggersEffective verify if the different
 *   errors are thrown.
 *   TestsMessages: Checks the output of the error.
 */
CREATE OR REPLACE TRIGGER T4_EFF_ROOT_UNDEL
  BEFORE DELETE ON LOGDATA.CONF_LOGGERS_EFFECTIVE
  REFERENCING OLD AS O
  FOR EACH ROW
 WHEN (O.LOGGER_ID = 0)
  T4_EFF_ROOT_UNDEL: BEGIN

   -- Debug
   -- INSERT INTO LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (5, -1, '>< T4_EFF_ROOT_UNDEL');

   SIGNAL SQLSTATE VALUE 'LG0E2'
     SET MESSAGE_TEXT = 'ROOT logger cannot be deleted';
  END T4_EFF_ROOT_UNDEL @

COMMENT ON TRIGGER T4_EFF_ROOT_UNDEL IS
  'Verifies that the root logger is not deleted from the effective table.
This is the basic logger and it should always exist in this table.'@

-- Table LOGDATA.APPENDERS.

/**
 * Checks that the appender_id for an appender is greater or equal to zero.
 *
 * TESTS
 *   TestsAppenders: Verifies the modification of Appenders.
 *   TestsMessages: Checks the output of the error.
 */
CREATE OR REPLACE TRIGGER T1_APP_GE_0
  BEFORE INSERT OR UPDATE ON LOGDATA.APPENDERS
  REFERENCING NEW AS N
  FOR EACH ROW
 WHEN (N.APPENDER_ID < 0)
  T1_APP_GE_0: BEGIN
   SIGNAL SQLSTATE VALUE 'LG0A1'
     SET MESSAGE_TEXT = 'APPENDER_ID for appenders should be greater or equal to zero';
  END T1_APP_GE_0 @

COMMENT ON TRIGGER T1_APP_GE_0 IS
  'Checks that the appender_id for an appender is greater or equal to zero'@

-- Table LOGDATA.CONF_APPENDERS.

/**
 * Removes the spaces around a pattern of an appender.
 */
CREATE OR REPLACE TRIGGER T1_CNF_APP_PATT
  BEFORE INSERT OR UPDATE ON LOGDATA.CONF_APPENDERS
  REFERENCING NEW AS N
  FOR EACH ROW
 T1_CNF_APP_PATT: BEGIN
  SET N.PATTERN = TRIM(N.PATTERN);
 END T1_CNF_APP_PATT @

COMMENT ON TRIGGER T1_CNF_APP_PATT IS 'Removes the spaces around a pattern of an appender'@

-- Table LOGDATA.LOGS.

/**
 * Generates a unique date for the logs.
 */
CREATE OR REPLACE TRIGGER T1_LGS_UNI_DATE
  BEFORE INSERT ON LOGDATA.LOGS
  REFERENCING NEW AS N
  FOR EACH ROW
  -- TODO Test if this call is expensive.
  SET N.DATE = GENERATE_UNIQUE() @

COMMENT ON TRIGGER T1_LGS_UNI_DATE IS 'Generates a unique date for the logs'@

