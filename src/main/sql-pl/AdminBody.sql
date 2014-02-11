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

SET CURRENT SCHEMA LOGGER_1A @

/**
 * Constant for the defaultRootLevelId value.
 */
ALTER MODULE LOGADMIN ADD
  VARIABLE DEFAULT_ROOT_LEVEL_ID ANCHOR LOGDATA.CONFIGURATION.KEY CONSTANT 'defaultRootLevelId' @

/**
 * Returns an opened cursor with the level names and complete logger names of
 * the used loggers that are registered in the conf_loggers_effective table.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE SHOW_LOGGERS (
  )
  LANGUAGE SQL
  SPECIFIC P_SHOW_LOGGERS
  DYNAMIC RESULT SETS 1
  READS SQL DATA
  NOT DETERMINISTIC -- Could be deterministic if conf logger is not deleted.
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
 * IN MIN_LEVEL
 *   Minimum level presented. If -1, only internal logging is presented.
 */
ALTER MODULE LOGADMIN ADD
  PROCEDURE LOGS (
  IN LENGTH SMALLINT DEFAULT 72,
  IN QTY SMALLINT DEFAULT 100,
  IN MIN_LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID DEFAULT NULL
  )
  LANGUAGE SQL
  SPECIFIC P_LOGS
  DYNAMIC RESULT SETS 1
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_LOGS: BEGIN
  DECLARE STMT ANCHOR LOGDATA.LOGS.MESSAGE;
  DECLARE C CURSOR
    WITH RETURN TO CALLER
    FOR RS;

  SET STMT = 'SELECT TIME, MESSAGE FROM ('
    || 'SELECT SUBSTR(TIMESTAMP(L.DATE), 12, 15) AS TIME, '
    || 'SUBSTR(L.MESSAGE, 1, ' || LENGTH || ') AS MESSAGE '
    || 'FROM LOGDATA.LOGS AS L ';
  IF (MIN_LEVEL = -1) THEN
   SET STMT = STMT
     || 'WHERE L.LEVEL_ID = -1 OR L.LEVEL_ID IS NULL ';
  ELSEIF (MIN_LEVEL IS NOT NULL) THEN
   SET STMT = STMT
     || 'WHERE L.LEVEL_ID <= ' || MIN_LEVEL || ' '
     || 'AND L.LEVEL_ID >= 0 ';
  END IF;
  SET STMT = STMT
    || 'ORDER BY L.DATE DESC '
    || 'FETCH FIRST ' || QTY || ' ROWS ONLY '
    || 'WITH UR '
    || ') ORDER BY TIME'
    ;
  IF (LOGGER.GET_VALUE(LOGGER.LOG_INTERNALS) = LOGGER.VAL_TRUE) THEN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES 
     (4, -1, 'Statement: ' || COALESCE(STMT,'NULL'));
   COMMIT;
  END IF;
  PREPARE RS FROM STMT;
  OPEN C;
 END P_LOGS @

/**
 * Function that returns the default logger level.
 * NOTE: If the levels are changed, this function should reflect those
 * modifications.
 *
 * RETURNS The configuration level for ROOT logger.
 */
ALTER MODULE LOGADMIN ADD
  FUNCTION GET_DEFAULT_LEVEL (
  ) RETURNS ANCHOR LOGDATA.LEVELS.LEVEL_ID
  LANGUAGE SQL
  SPECIFIC F_GET_DEFAULT_LEVEL
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 F_GET_DEFAULT_LEVEL: BEGIN
  DECLARE RET ANCHOR LOGDATA.LEVELS.LEVEL_ID;
  DECLARE VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

  -- Debug
  -- INSERT INTO LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 5, -1, 'aFLAG 6');

  SET VALUE = LOGGER.GET_VALUE(DEFAULT_ROOT_LEVEL_ID);
  SET RET = CAST(VALUE AS SMALLINT);
  RETURN RET;
 END F_GET_DEFAULT_LEVEL @

/**
 * Function that returns the ROOT logger level or default level.
 *
 * RETURNS The configuration level for ROOT logger.
 */
ALTER MODULE LOGADMIN ADD
  FUNCTION GET_ROOT_OR_DEFAULT_LEVEL (
  ) RETURNS ANCHOR LOGDATA.LEVELS.LEVEL_ID
  LANGUAGE SQL
  SPECIFIC F_GET_ROOT_OR_DEFAULT_LEVEL
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 F_GET_ROOT_OR_DEFAULT_LEVEL: BEGIN
  DECLARE RET ANCHOR LOGDATA.LEVELS.LEVEL_ID;

  SELECT LEVEL_ID INTO RET
    FROM LOGDATA.CONF_LOGGERS
    WHERE LOGGER_ID = 0;
  IF (RET IS NULL) THEN
   SET RET = GET_DEFAULT_LEVEL();
  END IF;
  RETURN RET;
 END F_GET_ROOT_OR_DEFAULT_LEVEL @

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
  LANGUAGE SQL
  SPECIFIC P_MODIFY_DESCENDANTS
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_MODIFY_DESCENDANTS: BEGIN
  DECLARE LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
  DECLARE LVL_ID ANCHOR LOGDATA.LEVELS.LEVEL_ID;

  -- Debug
  -- INSERT INTO LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 5, -1, 'aFLAG 5 = ' || coalesce (PARENT, -1) || '=' || coalesce (LEVEL, -1));

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
 END P_MODIFY_DESCENDANTS @

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
  SPECIFIC F_GET_DEFINED_PARENT_LOGGER
  MODIFIES SQL DATA
 F_GET_DEFINED_PARENT_LOGGER: BEGIN
  DECLARE RET ANCHOR LOGDATA.LEVELS.LEVEL_ID;
  DECLARE PARENT ANCHOR LOGDATA.CONF_LOGGERS.PARENT_ID;
  DECLARE EXISTS SMALLINT DEFAULT 0;

  -- Debug
  -- INSERT INTO LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 5, -1, 'aFLAG 1 - ' || coalesce (SON_ID, -1));

  IF (SON_ID IS NULL OR SON_ID < 0) THEN
   SIGNAL SQLSTATE VALUE 'LG0F1'
     SET MESSAGE_TEXT = 'Invalid parameter';
  ELSEIF (SON_ID = 0) THEN
   -- Asking for the level for ROOT.
   SELECT LEVEL_ID INTO RET
     FROM LOGDATA.CONF_LOGGERS
     WHERE LOGGER_ID = 0
     WITH UR;
   IF (RET IS NULL) THEN
    -- ROOT is not configured, getting the default value.
    SET RET = GET_DEFAULT_LEVEL();
   END IF;
  ELSE
   -- Checks if the level is defined in Conf_loggers
   SELECT 1 INTO EXISTS
     FROM LOGDATA.CONF_LOGGERS
     WHERE LOGGER_ID = SON_ID
     WITH UR;

   -- Debug
   -- INSERT INTO LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 5, -1, 'aFLAG 2 - ' || coalesce (EXISTS, -1));

   IF (EXISTS = 1) THEN
    -- Asking for a value different to ROOT.
    -- Retrieving the parent for the current logger.
    SELECT PARENT_ID INTO PARENT
      FROM LOGDATA.CONF_LOGGERS
      WHERE LOGGER_ID = SON_ID
      WITH UR;
    -- Retrieving the configured level for the parent.
    SELECT LEVEL_ID INTO RET
      FROM LOGDATA.CONF_LOGGERS
      WHERE LOGGER_ID = PARENT
      WITH UR;
    IF (RET IS NULL) THEN

     -- Debug
     -- INSERT INTO LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 5, -1, 'aFLAG 3 - ' || coalesce (PARENT, -1));

     -- The parent has not a configured level, doing a recursion.
     BEGIN
      DECLARE STMT STATEMENT;
      PREPARE STMT FROM 'SET ? = GET_DEFINED_PARENT_LOGGER(?)';
      EXECUTE STMT INTO RET USING PARENT;
     END;
    END IF;
   ELSE
    -- The given son is not configured in the Conf_loggers table.
    SELECT PARENT_ID INTO PARENT
      FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
      WHERE LOGGER_ID = SON_ID
      WITH UR;

    -- Debug
    -- INSERT INTO LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 5, -1, 'aFLAG 4 - ' || coalesce (PARENT, -1));

    IF (PARENT IS NULL) THEN
     -- The logger has not been defined in effective.
     SET RET = GET_ROOT_OR_DEFAULT_LEVEL();
    ELSE
     -- Retrieving the configured level for the parent.
     SELECT LEVEL_ID INTO RET
       FROM LOGDATA.CONF_LOGGERS
       WHERE LOGGER_ID = PARENT
       WITH UR;

     IF (RET IS NULL) THEN

      -- The parent could be defined, doing a recursion.
      BEGIN
       DECLARE STMT STATEMENT;
       PREPARE STMT FROM 'SET ? = GET_DEFINED_PARENT_LOGGER(?)';
       EXECUTE STMT INTO RET USING PARENT;
      END;
     END IF;
    END IF;
   END IF;
  END IF;

  -- Debug
  -- INSERT INTO LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 5, -1, 'aRET - ' || coalesce (RET, -1));

  RETURN RET;
 END F_GET_DEFINED_PARENT_LOGGER @
 
 