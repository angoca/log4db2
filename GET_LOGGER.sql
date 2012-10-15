--#SET TERMINATOR @
SET CURRENT SCHEMA LOGGER_1A @

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

-- TODO Create a SP that register a logger with a given level. This will create
-- all the levels in the conf_loggers, and the relations.

/**
 * Names of the registered loggers. This array is limited to the size of the
 * array, in this case 100.
 */
--ALTER MODULE LOGGER ADD
--  TYPE LOGGERS_NAMES_TYPE AS ANCHOR COMPLETE_LOGGER_NAME ARRAY [100] @

/**
 * Logger's names.
 */
--ALTER MODULE LOGGER ADD
--  VARIABLE LOGGERS_NAMES LOGGERS_NAMES_TYPE @

/**
 * Registers the logger name in the system, and retrieves the corresponding ID
 * for that logger. This ID will allow to write messages into that logger if
 * the configuration level allows it. This method processes the logger name
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
  IF (GET_VALUE(LOGGER.LOG_INTERNALS) = LOGGER.VAL_TRUE) THEN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES 
     (4, -1, 'Getting logger name for ' || COALESCE(NAME, 'null'));
  END IF;
  -- Checks the value in the cache if active.
  BEGIN
   DECLARE CONTINUE HANDLER FOR SQLSTATE '2202E'
     SET LOGGER_ID = NULL;
   IF (CACHE = TRUE) THEN
    SET LOGGER_ID = LOGGERS[NAME];
   END IF;
  END;
  IF (LOGGER_ID IS NULL) THEN
   BEGIN
    -- Declare variables.
    DECLARE LENGTH SMALLINT; -- Length of the logger name. Limits the guard.
    DECLARE POS SMALLINT; -- Position of a dot sign. Checks the boucle guard.
    DECLARE SUBS_PRE ANCHOR COMPLETE_LOGGER_NAME; -- Sustring before the dot.
    DECLARE SUBS_POS ANCHOR COMPLETE_LOGGER_NAME; -- Substring after the dot (current loop.)

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
    DECLARE PROCEDURE ANALYZE_NAME (
      IN STRING ANCHOR COMPLETE_LOGGER_NAME,
      INOUT PARENT ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
      INOUT PARENT_LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID
      )
     P_ANALYZE: BEGIN
      DECLARE SON ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID; -- Id of the current logger.
      DECLARE LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID; -- Id of the associated logger level.

      -- Looks for the logger with the given name in the configuration table.
      -- This query waits for the data to be commited (CS Cursor stability)
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
         AND C.PARENT_ID = PARENT
         WITH UR;
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
    -- This query waits for the data to be commited (CS Cursor stability)
    SELECT C.LEVEL_ID INTO PARENT_LEVEL
      FROM LOGDATA.CONF_LOGGERS C
      WHERE C.LOGGER_ID = 0
      WITH UR;
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
    -- Adds this logger name in the cache.
    IF (CACHE = TRUE) THEN
     BEGIN
      --DECLARE POS SMALLINT;
      SET LOGGERS[NAME] = LOGGER_ID;
      --SET POS = CARDINALITY(LOGGERS_NAMES);
      --IF (POS IS NULL) THEN
       --SET POS = 1;
      --END IF;
      --SET LOGGERS_NAMES[POS + 1] = NAME;
      -- Internal logging.
      IF (GET_VALUE(LOGGER.LOG_INTERNALS) = LOGGER.VAL_TRUE) THEN
       INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES 
         (4, -1, 'Logger not in cache ' || NAME || ' with ' || LOGGER_ID );--|| ' pos ' || POS);
      END IF;
     END;
    END IF;
   END;
  END IF;
  -- Internal logging.
  IF (GET_VALUE(LOGGER.LOG_INTERNALS) = LOGGER.VAL_TRUE) THEN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, LOGGER_ID, MESSAGE) VALUES 
     (4, -1, 'Logger ID for ' || NAME || ' is ' || COALESCE(LOGGER_ID, -1));
  END IF;
 END P_GET_LOGGER @