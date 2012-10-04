--#SET TERMINATOR @
SET CURRENT SCHEMA LOGGER @

-- TODO Check the logger structure, in order to have different names for the
-- sons of a given father. root>toto root>tata root>tata is an error, and should
-- remove this duplicate. Probably implement with a check constraint.

-- TODO Check the IDs of the conf table and the effective table, in order to
-- see if the effective ids correspond to conf ids.

-- TODO Check if the logger levels between the conf and effective table are the
-- same. In conf could be INFO but in effective could be WARN.@ @

-- TODO Check the registered loggers in the database, calculating the maximum
-- length of the concatenated inner levels, and this lenght should be less than
-- 256 chars. foo.bar.toto

-- TODO Add the optimized for

-- TODO Add the fetch first N rows only

-- TODO Add the isolation level.

-- TODO Create a trigger for CONF_LOGGER that each time a line is added, it
-- creates the row in the effective table and retrieve the generate ID of that
-- table and insertes the same in this table.

-- TODO Create a function / procedure that shows a table of all posible
-- loggers in the system and their levels. This graphical representation
-- helps to see the established configuration.
-- info ROOT
-- info foo
-- debug foo.bar
-- info tata

-- TODO Create a view on the log table, that show directly the level name.
-- It is useful because it already done the join.

-- TODO Create a SP that register a logger with a given level. This will create
-- all the levels in the conf_loggers, and the relations.

-- TODO Validar cuando se borra un registro de effective, que tambi<E9>n se debe
-- borrar de conf_loggers. Esto hacerlo con un trigger.

/**
 * Registers the logger name in the system, and retrieves the corresponding ID
 * for that logger. This ID will allow to write messages into that logger if
 * the level configuration allows it. This method processes the logger name
 * in order to remove any leading or trailing whitespace or dot.
 *
 * IN NAME
 *   Name of the logger. This string has to be separated by dots to
 *   differenciate the levels. e.g.: foo.bar.toto, where foo is the first level,
 *   bar is the second and toto is the last one.
 *   The name could have a maximum of 256 characters, representing just one
 *   level, or several levels with short names.
 * OUT LOGGER_ID
 *   The ID of the logger.
 */

ALTER MODULE LOGGER ADD
  PROCEDURE GET_LOGGER (
  IN NAME VARCHAR(256),
  OUT LOGGER_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  )
  LANGUAGE SQL
  SPECIFIC P_GET_LOGGER
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  DETERMINISTIC -- Returns the same ID for the same logger name.
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_GET_LOGGER: BEGIN
  -- Declare variables.
  DECLARE LENGTH SMALLINT; -- Length of the logger name. Limits the guard.
  DECLARE POS SMALLINT; -- Position of a dot sign. Checks the boucle guard.
  DECLARE SUBS_PRE VARCHAR(256); -- Sustring before the dot.
  DECLARE SUBS_POS VARCHAR(256); -- Substring after the dot (current loop.)
  
  DECLARE PARENT ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID; -- Parent Id of the current logger.
  DECLARE PARENT_LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID; -- Id of the parent level.
  
  /**
   * Internal method that analyzes a string against the tables to see if the
   * level name is already registered there, and finally retrieves the logging
   * level and logger id.
   *
   * IN STRING
   *   This is the string to analyze.
   * INOUT PARENT SMALLINT
   *   Enters as the parent Id of this string, and goes out as the new id.
   * INOUT PARENT_LEVEL
   *   Logger level (parent -> son).
   */
  DECLARE  PROCEDURE ANALYZE_NAME (
    IN STRING VARCHAR(256),
    INOUT PARENT ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
    INOUT PARENT_LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID
    )
   P_ANALYZE: BEGIN
    DECLARE SON ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID; -- Id of the current logger.
    DECLARE LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID; -- Id of the associated logger level.

    -- Looks for the logger with the given name in the configuration table.
    SELECT C.LOGGER_ID, C.LEVEL_ID INTO SON, LEVEL
      FROM LOGDATA.CONF_LOGGERS C 
      WHERE C.NAME = STRING
      AND C.PARENT_ID = PARENT;
    -- If the logger is NOT already registered.
    IF (SON IS NULL) THEN
     -- Searches in the effective configuration if this is already registered.
     SELECT C.LOGGER_ID, C.LEVEL_ID INTO SON, LEVEL
       FROM LOGDATA.CONF_LOGGERS_EFFECTIVE C
       WHERE C.NAME = STRING
       AND C.PARENT_ID = PARENT;
     -- Logger is NOT registered in none of the tables.
     IF (SON IS NULL) THEN
      -- Registers the new logger and retrieves the id. Switches the parent id.
      SELECT LOGGER_ID INTO PARENT FROM FINAL TABLE (
        INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID)
        VALUES (STRING, PARENT, PARENT_LEVEL));
     ELSE
      -- It is already register in the effective table, thus take the id of that
      -- logger as parent.
      SET PARENT = SON;
      SET PARENT_LEVEL = LEVEL;
     END IF;
    ELSE
     -- It is registered in the configuration table, thus take the id of that
     -- logger.
     SET PARENT = SON;
     SET PARENT_LEVEL = LEVEL;
    END IF;
   END P_ANALYZE ;
  ------------------------------------------------------------------------------

  -- Remove spaces at the beginning and at the end.
  SET NAME = TRIM(BOTH FROM NAME);
  -- Remove dots at the beginning and at the end.
  SET NAME = TRIM(BOTH '.' FROM NAME);

  SET LENGTH = LENGTH(NAME);
  SET SUBS_POS = NAME;
  SET POS = 0;
  SET PARENT = 0; -- Root logger is always 0.
  -- Retrieves the logger level for the root logger.
  SELECT C.LEVEL_ID INTO PARENT_LEVEL
    FROM LOGDATA.CONF_LOGGERS C
    WHERE C.LOGGER_ID = 0;
  -- TODO To check the value defaultRootLevel before assign Warn as default.
  -- If the root logger is not defined, then set the default level: WARN-3.
  IF (PARENT_LEVEL IS NULL) THEN
   SET PARENT_LEVEL = 2;
  END IF;
  
  -- Takes each level of the logger name (dots), and retrieves or creates the
  -- hierarchy in the configutation.
  WHILE (POS < LENGTH) DO
   SET POS = POSSTR (SUBS_POS, '.');
   -- If different to zero means that a dot was found => Root level.
   IF (POS <> 0) THEN
    -- Current logger level in hierarchy.
    SET SUBS_PRE = SUBSTR(SUBS_POS, 1, POS - 1);
    -- Rest of the logger name.
    SET SUBS_POS = SUBSTR(SUBS_POS, POS + 1);

    CALL ANALYZE_NAME(SUBS_PRE, PARENT, PARENT_LEVEL);
   ELSE -- No dot was found (in the remainding string).
    CALL ANALYZE_NAME(SUBS_POS, PARENT, PARENT_LEVEL);
    -- Ends the while.
    SET POS = LENGTH;
   END IF;
  END WHILE;
  SET LOGGER_ID = PARENT;
  -- Internal logging.
  IF (GET_VALUE(LOGGER.LOG_INTERNALS) = LOGGER.VAL_TRUE) THEN
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES 
      (4, -1, 'Logger ID for ' || NAME || ' is ' || LOGGER_ID);
  END IF;
 END P_GET_LOGGER @

/**
 * Returns a open cursor with the level names and complete logger names of the
 * used loggers that are registered in the conf_loggers_effective table.
 */
ALTER MODULE LOGGER ADD
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
    WITH RETURN TO CALLER 
    FOR 
    SELECT L.NAME AS LEVEL, GET_LOGGER_NAME(LOGGER_ID) AS NAME
    FROM LOGDATA.CONF_LOGGERS_EFFECTIVE E,
    LOGDATA.LEVELS L
    WHERE E.LEVEL_ID = L.LEVEL_ID
    ORDER BY LOGGER_ID;
  OPEN C;
 END P_SHOW_LOGGERS @

/**
 * Returns an opened cursor showing the log messages truncated and the date.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE LOGS ()
  LANGUAGE SQL
  SPECIFIC P_LOGS
  DYNAMIC RESULT SETS 1
  READS SQL DATA
  DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_LOGS: BEGIN
  -- The max is hardcoded to 72. When this value is dynamic, the screen output
  -- is not reduced, and for this reason the message has to be truncated.
  DECLARE C CURSOR
    WITH RETURN TO CALLER 
    FOR 
    SELECT SUBSTR(DATE,12,15) AS TIME, SUBSTR(MESSAGE, 1, 72) AS MESSAGE
   FROM LOGDATA.LOGS
   ORDER BY DATE;
  OPEN C;
 END P_LOGS @