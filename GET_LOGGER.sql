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
 * RETURNS The ID of the logger.
 */

ALTER MODULE LOGGER ADD
 FUNCTION GET_LOGGER (
  IN NAME VARCHAR(256)
 ) RETURNS ANCHOR LOGGER.CONF_LOGGERS.LOGGER_ID
 -- TODO NO EXTERNAL ACTION
 MODIFIES SQL DATA
 F_GET_LOGGER: BEGIN
  -- Declare variables.
  DECLARE LENGTH SMALLINT; -- Length of the logger name. Limits the guard.
  DECLARE POS SMALLINT; -- Position of a dot sign. Checks the boucle guard.
  DECLARE SUBS_PRE VARCHAR(256); -- Sustring before the dot.
  DECLARE SUBS_POS VARCHAR(256); -- Substring after the dot (current loop.)
  
  DECLARE PARENT SMALLINT; -- Parent Id of the current logger.
  DECLARE SON SMALLINT; -- Id of the current logger.
  DECLARE PARENT_LEVEL SMALLINT; -- Id of the parent level.
  DECLARE LEVEL SMALLINT; -- Id of the associated level for the logger.
  
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
  FROM CONF_LOGGERS C
  WHERE C.LOGGER_ID = 0;
  -- TODO To check the value defaultRootLevel before assign Warn as default.
  -- If the root logger is not defined, then set the default level: WARN-3.
  IF (LEVEL_ID IS NULL) THEN
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

    -- Looks for the logger with the given name in the configuration table.
    SELECT C.LOGGER_ID, C.LEVEL_ID INTO SON, LEVEL
      FROM CONF_LOGGERS C 
      WHERE C.NAME = SUBS_PRE
      AND C.PARENT_ID = PARENT;

    -- If the logger is NOT already registered.
    IF (SON IS NULL) THEN
     -- Searches in the effective configuration if this is already registered.
     SELECT C.LOGGER_ID, C.LEVEL_ID INTO SON, LEVEL
       FROM CONF_LOGGERS_EFFECTIVE C
       WHERE C.NAME = SUBS_PRE
       AND C.PARENT_ID = PARENT;

     -- Logger is NOT registered in none of the tables.
     IF (SON IS NULL) THEN
     
      -- Registers the new logger and retrieves the id.
      SELECT LOGGER_ID INTO PARENT FROM FINAL TABLE (
        INSERT INTO CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID)
        VALUES (SUBS_PRE, PARENT, PARENT_LEVEL));
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
   ELSE -- No dot was found (in the remainding string).
    -- Looks for the logger with the given name in the configuration table.
    SELECT C.LOGGER_ID, C.LEVEL_ID INTO SON, LEVEL
      FROM CONF_LOGGERS C 
      WHERE C.NAME = SUBS_POS
      AND C.PARENT_ID = PARENT;

    -- If the logger is NOT already registered.
    IF (SON IS NULL) THEN
    
     -- Searches in the effective configuration if this is already registered.
     SELECT C.LOGGER_ID, C.LEVEL_ID INTO SON, LEVEL
       FROM CONF_LOGGERS_EFFECTIVE C
       WHERE C.NAME = SUBS_POS
       AND C.PARENT_ID = PARENT;

     -- Logger is NOT registered in none of the tables.
     IF (SON IS NULL) THEN
     
      -- Registers the new logger and retrieves the id.
      SELECT LOGGER_ID INTO PARENT FROM FINAL TABLE (
      INSERT INTO CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID)
        VALUES (SUBS_POS, PARENT, PARENT_LEVEL));
     ELSE
      -- It is already register in the effective table, thus take the id of that
      -- logger as parent.
      SET PARENT = SON;
      
     END IF;
    ELSE
     -- It is registered in the configuration table, thus take the id of that
     -- logger.
     SET PARENT = SON;
    END IF;
       
    -- Ends the while.
    SET POS = LENGTH;
   END IF;
   -- No son for the next iteration.
   SET SON = NULL;
  END WHILE;
  
  RETURN PARENT;
 END F_GET_LOGGER
 
 -- TODO Check the logger structure, in order to have different names for the
 -- sons of a given father. root>toto root>tata root>tata is an error, and should
 -- remove this duplicate. Probably implement with a check constraint.
 
 -- TODO Check the IDs of the conf table and the effective table, in order to
 -- see if the effective ids correspond to conf ids.
 
 -- TODO Check if the logger levels between the conf and effective table are the
 -- same. In conf could be INFO but in effective could be WARN.@ @