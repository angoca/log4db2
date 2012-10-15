--#SET TERMINATOR @
SET CURRENT SCHEMA LOGGER_1A @

/**
 * Constant for the defaultRootLevel value.
 */
ALTER MODULE LOGADMIN ADD
  VARIABLE DEFAULT_ROOT_LEVEL ANCHOR LOGDATA.CONFIGURATION.KEY CONSTANT 'defaultRootLevel' @

/**
 * Constant for the logger level value OFF in configuration.
 */
ALTER MODULE LOGADMIN ADD
  VARIABLE LEVEL_OFF ANCHOR LOGDATA.CONFIGURATION.VALUE CONSTANT 'OFF' @

/**
 * Constant for the logger level value FATAL in configuration.
 */
ALTER MODULE LOGADMIN ADD
  VARIABLE LEVEL_FATAL ANCHOR LOGDATA.CONFIGURATION.VALUE CONSTANT 'FATAL' @

/**
 * Constant for the logger level value ERROR in configuration.
 */
ALTER MODULE LOGADMIN ADD
  VARIABLE LEVEL_ERROR ANCHOR LOGDATA.CONFIGURATION.VALUE CONSTANT 'ERROR' @

/**
 * Constant for the logger level value WARN in configuration.
 */
ALTER MODULE LOGADMIN ADD
  VARIABLE LEVEL_WARN ANCHOR LOGDATA.CONFIGURATION.VALUE CONSTANT 'WARN' @

/**
 * Constant for the logger level value INFO in configuration.
 */
ALTER MODULE LOGADMIN ADD
  VARIABLE LEVEL_INFO ANCHOR LOGDATA.CONFIGURATION.VALUE CONSTANT 'INFO' @

/**
 * Constant for the logger level value DEBUG in configuration.
 */
ALTER MODULE LOGADMIN ADD
  VARIABLE LEVEL_DEBUG ANCHOR LOGDATA.CONFIGURATION.VALUE CONSTANT 'DEBUG' @

/**
 * Returns an opened cursor with the level names and complete logger names of
 * the used loggers that are registered in the conf_loggers_effective table.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE SHOW_LOGGERS ()
  LANGUAGE SQL
  SPECIFIC P_SHOW_LOGGERS
  DYNAMIC RESULT SETS 1
  READS SQL DATA
  DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_SHOW_LOGGERS: BEGIN
  DECLARE C CURSOR
    WITH RETURN TO CLIENT 
    FOR 
    SELECT L.NAME AS LEVEL, LOGGER.GET_LOGGER_NAME(LOGGER_ID) AS NAME
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE E,
    LOGDATA.LEVELS L
    WHERE E.LEVEL_ID = L.LEVEL_ID
    ORDER BY LOGGER_ID
    WITH UR;

  OPEN C;
 END P_SHOW_LOGGERS @

/**
 * Returns an opened cursor showing the log messages truncated to 72 characters
 * by default, the date limited to the hour part with miliseconds, and just the
 * last 100 (by deafult) log messages registered. The concurrence is uncommited
 * read. This procedure is useful to be called with named parameter, for
 * example: CALL LOGS (QTY => 50)
 *
 * IN LENGTH
 *   Message length. By default this value is 72 characters.
 * IN QTY
 *   Quantity of messages to return in the cursor.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE LOGS (
  IN LENGTH SMALLINT DEFAULT 72,
  IN QTY SMALLINT DEFAULT 100
  )
  LANGUAGE SQL
  SPECIFIC P_LOGS
  DYNAMIC RESULT SETS 1
  MODIFIES SQL DATA
  DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_LOGS: BEGIN
  DECLARE STMT VARCHAR(256);
  DECLARE C CURSOR
    WITH RETURN TO CALLER
    FOR RS;

  SET STMT = 'SELECT TIME, MESSAGE FROM ('
    || 'SELECT SUBSTR(TIMESTAMP(L.DATE), 12, 15) AS TIME, '
    || 'SUBSTR(L.MESSAGE, 1, ' || LENGTH || ') AS MESSAGE '
    || 'FROM LOGDATA.LOGS AS L '
    || 'ORDER BY DATE DESC '
    || 'FETCH FIRST ' || QTY || ' ROWS ONLY '
    || 'WITH UR '
    || ') ORDER BY TIME'
    ;
  IF (LOGGER.GET_VALUE(LOGGER.LOG_INTERNALS) = LOGGER.VAL_TRUE) THEN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES 
     (4, -1, 'Statement: ' || STMT);
   COMMIT;
  END IF;
  PREPARE RS FROM STMT;
  OPEN C;
 END P_LOGS @

/**
 * Function that returns the default ROOT logger level.
 *
 * RETURNS The configuration level for ROOT logger.
 */
ALTER MODULE LOGADMIN ADD
  FUNCTION GET_ROOT_OR_DEFAULT_LEVEL (
  ) RETURNS ANCHOR LOGDATA.LEVELS.LEVEL_ID
 P_DEFAULT_ROOT: BEGIN
  DECLARE RET ANCHOR LOGDATA.LEVELS.LEVEL_ID;

  SELECT LEVEL_ID INTO RET
    FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID = 0;
  IF (RET IS NULL) THEN
   SET RET = CASE LOGGER.GET_VALUE(DEFAULT_ROOT_LEVEL) 
     WHEN LEVEL_OFF THEN 0
     WHEN LEVEL_FATAL THEN 1
     WHEN LEVEL_ERROR THEN 2
     WHEN LEVEL_WARN THEN 3
     WHEN LEVEL_INFO THEN 4
     WHEN LEVEL_DEBUG THEN 5
     ELSE 3
     END;
  END IF;
  RETURN RET;
 END P_DEFAULT_ROOT @

/**
 * Modifies the descendancy of the provided logger changing the level to the
 * given one.
 *
 * IN PARENT
 *   Parent of the descendancy to be changed.
 * IN LEVEL
 *   Log level to be assigned to all descendancy.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE MODIFY_DESCENDANTS (
  IN PARENT ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID
  )
 P_MODIFY_DESC: BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE LVL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID;

  IF (PARENT IS NULL OR PARENT < 0 OR LEVEL IS NULL OR LEVEL < 0) THEN
   SIGNAL SQLSTATE VALUE 'LG002'
     SET MESSAGE_TEXT = 'Invalid parameter';
  END IF;
  -- Analyzes all sons for the given parent.
  FOR F AS C CURSOR FOR
    SELECT LOGGER_ID AS LOG_ID
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
    WHERE PARENT_ID = PARENT
    FOR UPDATE
    DO
   -- Checks if the level has a configured level, or it is inherited.
   SELECT LEVEL_ID INTO LVL_ID
     FROM LOGDATA.CONF_LOGGERS
     WHERE LOGGER_ID = LOG_ID;
   IF (LVL_ID IS NULL) THEN
    -- Updates the current logger_id (son.)
    UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
      SET LEVEL_ID = LEVEL
      WHERE CURRENT OF C;
    -- Modifies the descendant level (recursion).
    BEGIN
     DECLARE STMT STATEMENT;
     PREPARE STMT FROM 'CALL MODIFY_DESCENDANTS (?, ?)';
     EXECUTE STMT USING LOG_ID, LEVEL;
    END;
   END IF;
  END FOR;
 END P_MODIFY_DESC @

/**
 * Function that retrieves the defined log level from the closer ascendency.
 *
 * IN SON_ID
 *   Logger id that will be analyzed to find a ascendency with a defined log
 *   level.
 * RETURNS The log level configured to a ascendancy or the default value.
 *   
 */
ALTER MODULE LOGADMIN ADD
  FUNCTION GET_DEFINED_PARENT_LOGGER (
  IN SON_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  ) RETURNS ANCHOR LOGDATA.LEVELS.LEVEL_ID
 T_GET_UPPER_DEFINED: BEGIN
  DECLARE RET ANCHOR LOGDATA.LEVELS.LEVEL_ID;
  DECLARE PARENT ANCHOR LOGDATA.CONF_LOGGERS.PARENT_ID;

  IF (SON_ID IS NULL OR SON_ID < 0) THEN
   SIGNAL SQLSTATE VALUE 'LG001'
     SET MESSAGE_TEXT = 'Invalid parameter';
  ELSEIF (SON_ID = 0) THEN
   -- Asking for the level for ROOT.
   SELECT LEVEL_ID INTO RET
     FROM LOGDATA.CONF_LOGGERS
     WHERE LOGGER_ID = 0;
   IF (RET IS NULL) THEN
    -- ROOT is not configured, getting the default value.
    SET RET = GET_ROOT_OR_DEFAULT_LEVEL();
   END IF;
  ELSE
   -- Asking for a value different to ROOT.
   -- Retrieving the parent for the current logger.
   SELECT PARENT_ID INTO PARENT
     FROM LOGDATA.CONF_LOGGERS
     WHERE LOGGER_ID = SON_ID;
   -- Retrieveing the configured level for the parent.
   SELECT LEVEL_ID INTO RET
     FROM LOGDATA.CONF_LOGGERS
     WHERE LOGGER_ID = PARENT;
   IF (PARENT IS NULL) THEN
    SET RET = GET_ROOT_OR_DEFAULT_LEVEL();
   ELSEIF (RET IS NULL) THEN
    -- The parent has not a configured level, doing a recursion.
    BEGIN
     DECLARE STMT STATEMENT;
     PREPARE STMT FROM 'SET ? = GET_DEFINED_PARENT_LOGGER(?)';
     EXECUTE STMT INTO RET USING PARENT;
    END;
   END IF;
  END IF;
  RETURN RET;
 END T_GET_UPPER_DEFINED @