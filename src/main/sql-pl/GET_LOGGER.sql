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
 * Contains the complete implementation of the GET_LOGGER procedure. This is one
 * of the most important and longest routines in the utility; for this reason it
 * is in a dedicated file.
 *
 * Version: 2014-02-14 1-Alpha
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

-- TODO Check if the logger levels between the conf and effective table are the
-- same. In conf could be INFO but in effective could be WARN.

-- TODO Check the registered loggers in the database, calculating the maximum
-- length of the concatenated inner levels, and this lenght should be less than
-- 256 chars. foo.bar.toto

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
 * OUT LOG_ID
 *   The ID of the logger.
 * PRE
 *   Root logger exist.
 * POS
 *   If the given name is valid, a valid ID is returned that correspond to the
 *   last son in the hierarchy.
 * TESTS
 *   TestsCascadeCallLimit: Allows to verify the quantity of levels, and to
 *   register all messages.
 *   TestsGetLogger: Verifies the inputs of this procedure, and checks the
 *   outputs.
 *   TestsMessages: Checks the output of the error.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE GET_LOGGER (
  IN NAME ANCHOR COMPLETE_LOGGER_NAME,
  OUT LOG_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID
  )
  LANGUAGE SQL
  SPECIFIC P_GET_LOGGER
  DYNAMIC RESULT SETS 0
  MODIFIES SQL DATA
  NOT DETERMINISTIC -- It was deterministic because it could return the same ID
                    -- for the same logger name. However, if the configuration
                    -- is deleted, a new logger_id should be retrieved.
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_GET_LOGGER: BEGIN
  DECLARE INTERNAL BOOLEAN DEFAULT FALSE; -- Internal logging.
  -- Handles the limit cascade call.
  DECLARE EXIT HANDLER FOR SQLSTATE '54038'
   BEGIN
    INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES 
      (2, 'LG001. Cascade call limit achieved, for GET_LOGGER: ' || COALESCE(NAME, 'null'));
    RESIGNAL SQLSTATE 'LG001'
      SET MESSAGE_TEXT = 'Cascade call limit achieved. Log message was written';
   END;

  -- Internal logging.
  IF (GET_VALUE(LOG_INTERNALS) = VAL_TRUE) THEN
   SET INTERNAL = TRUE;
  END IF;

  IF (INTERNAL = TRUE) THEN
   INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES 
     (GENERATE_UNIQUE(), 4, -1, 'Getting logger name for ' || COALESCE(NAME, 'null'));
  END IF;

  -- Validate nullability
  IF (NAME IS NULL) THEN
   SET NAME ='';
  END IF;

  -- Checks the value in the cache if active.
  BEGIN
   DECLARE CONTINUE HANDLER FOR SQLSTATE '2202E'
     SET LOG_ID = NULL;
   IF (CACHE = TRUE) THEN
    SET LOG_ID = LOGGERS_ID_CACHE[NAME];
   END IF;
  END;
  IF (LOG_ID IS NULL) THEN
   BEGIN
    -- Declare variables.
    DECLARE LENGTH SMALLINT; -- Length of the logger name. Limits the guard.
    DECLARE POS SMALLINT; -- Position of a dot sign. Checks the boucle guard.
    DECLARE SUBS_PRE ANCHOR COMPLETE_LOGGER_NAME; -- Sustring before the dot.
    DECLARE SUBS_POS ANCHOR COMPLETE_LOGGER_NAME; -- Substring after the dot (current loop.)

    DECLARE PARENT ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID; -- Parent Id of the current logger.
    DECLARE PARENT_LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID; -- Id of the parent level.
    DECLARE PARENT_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY; -- Hierarchy path.

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
     * IN PARENT_HIERARCHY
     *   Hierarchy's path - a comma separated logger IDs.
     */
    DECLARE PROCEDURE ANALYZE_NAME (
      IN STRING ANCHOR COMPLETE_LOGGER_NAME,
      INOUT PARENT ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
      INOUT PARENT_LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID,
      IN PARENT_HIERARCHY ANCHOR LOGDATA.CONF_LOGGERS_EFFECTIVE.HIERARCHY
      )
     P_ANALYZE_NAME: BEGIN
      DECLARE SON ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID; -- Id of the current logger.
      DECLARE LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID; -- Id of the associated logger level.

      -- Looks for the logger with the given name in the configuration table.
      -- This query waits for the data to be commited (CS Cursor stability)
      -- FIXME: Try to convert the following query to an array. Two fields are
      -- part of the key.
      SELECT C.LOGGER_ID, C.LEVEL_ID INTO SON, LEVEL
        FROM LOGDATA.CONF_LOGGERS C 
        WHERE C.NAME = STRING
        AND C.PARENT_ID = PARENT
        FETCH FIRST 1 ROW ONLY
        WITH CS;
      -- If the logger is NOT already registered.
      IF (SON IS NULL) THEN
       -- Registers the new logger and retrieves the id. Switches the parent id.
       INSERT INTO LOGDATA.CONF_LOGGERS (NAME, PARENT_ID, LEVEL_ID)
          VALUES(STRING, PARENT, NULL);
       SET PARENT = IDENTITY_VAL_LOCAL();
       -- Updates the hierarchy path.
       SET PARENT_HIERARCHY = PARENT_HIERARCHY || ',' || CHAR(PARENT);
       INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, LEVEL_ID, HIERARCHY)
         VALUES (PARENT, PARENT_LEVEL, PARENT_HIERARCHY);
      ELSE
       -- It is registered in the configuration table, thus take the id of that
       -- logger.
       SET PARENT = SON;
       SET PARENT_LEVEL = LEVEL;
      END IF;
     END P_ANALYZE_NAME ;
    ------------------------------------------------------------------------------

    -- Remove spaces at the beginning and at the end.
    SET NAME = TRIM(BOTH FROM NAME);
    -- Remove dots at the beginning and at the end.
    SET NAME = TRIM(BOTH '.' FROM NAME);

    SET LENGTH = LENGTH(NAME);
    SET SUBS_POS = NAME;
    SET POS = 0;
    SET PARENT = 0; -- Root logger is always 0.
    SET PARENT_HIERARCHY = '0'; -- Hierarchy path for root.
    -- Retrieves the logger level for the root logger.
    SET PARENT_LEVEL = ROOT_CURRENT_LEVEL;
    -- If the root logger is not defined, then set the default level: WARN-3.
    IF (PARENT_LEVEL IS NULL) THEN
     SET PARENT_LEVEL = GET_DEFAULT_LEVEL();
    END IF;

    RECURSION : BEGIN
     DECLARE CONTINUE HANDLER FOR SQLSTATE '09000'
       BEGIN
        SET POS = LENGTH;
        SET PARENT = 0;
        INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES 
          (2, 'LG001. Cascade call limit achieved, for GET_LOGGER: '
          || COALESCE(NAME, 'null'));
       END;
        -- Takes each level of the logger name (dots), and retrieves or creates
        -- the hierarchy in the configutation.
     WHILE (POS < LENGTH) DO
      SET POS = POSSTR (SUBS_POS, '.');
      -- If different to zero means that a dot was found => Root level.
      IF (POS <> 0) THEN
       -- Current logger level in hierarchy.
       SET SUBS_PRE = SUBSTR(SUBS_POS, 1, POS - 1);
       -- Rest of the logger name.
       SET SUBS_POS = SUBSTR(SUBS_POS, POS + 1);

       CALL ANALYZE_NAME(SUBS_PRE, PARENT, PARENT_LEVEL, PARENT_HIERARCHY);
       SET PARENT_HIERARCHY = PARENT_HIERARCHY || ',' || PARENT;
      ELSE -- No dot was found (in the remainding string).
       CALL ANALYZE_NAME(SUBS_POS, PARENT, PARENT_LEVEL, PARENT_HIERARCHY);
       -- Ends the while.
       SET POS = LENGTH;
      END IF;
     END WHILE;
    END RECURSION;
    SET LOG_ID = PARENT;
    -- Adds this logger name in the cache.
    IF (CACHE = TRUE) THEN
     BEGIN
      SET LOGGERS_ID_CACHE[NAME] = LOG_ID;
      -- Internal logging.
      IF (INTERNAL = TRUE) THEN
       INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES 
         (GENERATE_UNIQUE(), 4, -1, 'Logger not in cache ' || NAME || ' with ' || LOG_ID );
      END IF;
     END;
    END IF;
   END;
  END IF;
  -- Internal logging.
  IF (INTERNAL = TRUE) THEN
   INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, LOGGER_ID, MESSAGE) VALUES 
     (GENERATE_UNIQUE(), 4, -1, 'Logger ID for ' || NAME || ' is ' || COALESCE(LOG_ID, -1));
  END IF;
 END P_GET_LOGGER @

