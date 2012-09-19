/**
 * Registers the logger name in the systems, and retrieves the corresponding ID
 * for the level of that logger. This id will allow to write messages into that
 * logger level. This method processes the logger name in order to remove any
 * leading or trailing whitespace or dot.
 *
 * IN NAME
 *     Name of the logger. This string has to be separated by dot to
 *     differenciate the levels. e.g. foo.bar.toto, where foo is the first
 *     level, bar is the second and toto is the last one.
 * RETURNS The Id of the logger level.
 */

ALTER MODULE LOGGER ADD
 FUNCTION GET_LOGGER (
  IN NAME VARCHAR(64)
 ) RETURNS ANCHOR LOGGER.CONF_LOGGERS.LOGGER_ID
 NO EXTERNAL ACTION
 F_GET_LOGGER: BEGIN
  -- Declare variables.
  DECLARE LENGTH SMALLINT; -- Quantity of levels.
  DECLARE COUNT SMALLINT; -- Index position in levels.
  DECLARE POS SMALLINT; -- Position of a dot sign.
  DECLARE SUBS_PRE VARCHAR(256); -- Sustring after the dot.
  DECLARE SUBS_POS VARCHAR(256); -- Substring before the dot (current.)
  -- TODO DECLARE HIERAR HIERARCHY_ARRAY; -- Array to store the hierarchy.
  
  DECLARE PARENT SMALLINT; -- Parent Id of the current logger.
  DECLARE SON SMALLINT; -- Id of the current logger.
  DECLARE LEVEL SMALLINT; -- Id of the associated level for the logger.
  
  -- Remove spaces at the beginning and at the end.
  SET NAME = TRIM(BOTH FROM NAME);
  -- Remove dots at the beginning and at the end.
  SET NAME = TRIM(BOTH '.' FROM NAME);

  SET SUBS_POS = NAME;
  SET LENGTH = LENGTH(SUBS_POS);
  SET POS = 0;
  SET COUNT = 1;
  SET PARENT = 0; -- Root logger is always 0.
  
  -- Takes each level of the logger name, and construct an array with the
  -- levels.
  INSERT INTO LOG VALUES (CURRENT TIMESTAMP, 'Here we go!');
  WHILE (POS < LENGTH) DO
   SET POS = POSSTR (SUBS_POS, '.');
   IF (POS <> 0) THEN
    --SET HIERAR[COUNT] 
    SET SUBS_PRE = SUBSTR(SUBS_POS, 1, POS - 1);
    SET COUNT = COUNT + 1;
    SET SUBS_POS = SUBSTR(SUBS_POS, POS + 1);

    SELECT LOGGER_ID, LEVEL_ID INTO SON, LEVEL
    FROM CONF_LOGGERS C 
    WHERE C.NAME = SUBS_PRE
    AND C.PARENT_ID = PARENT;

   ELSE
    SET POS = LENGTH;
   END IF;
  END WHILE;
  IF (LENGTH > 0) THEN
   SET HIERAR[COUNT] = SUBS_POS;
  END IF;
  
  SET COUNT = 1;
  SET LENGTH = CARDINALITY(HIERAR);
  
  -- Scans the configuration through the loggers, by searching the names.
  WHILE (COUNT < LENGTH) DO
   -- There is not an explicit configuration for this logger name.
   IF (PARENT IS NULL) THEN
    -- Searches in the effective configuration if this is already registered.
    SELECT LOGGER_ID, LEVEL_ID INTO PARENT, LEVEL
    FROM CONF_LOGGERS_EFFECTIVE C
    WHERE C.NAME = HIERAR[COUNT]
    AND C.PARENT_ID = PARENT;
    -- Not registered.
    IF (PARENT IS NULL) THEN
     INSERT INTO CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID)
     VALUES (HIERAR[COUNT], PARENT, LEVEL);
    ELSE
     -- It is already register in the effective table, thus take the id of that
     -- logger.
     SELECT LOGGER_ID INTO SON
     FROM CONF_LOGGERS_EFFECTIVE C
     WHERE C.NAME = HIERAR[COUNT]
     AND C.PARENT_ID = PARENT;
    END IF;
   ELSE
    -- It is registered in the configuration table, thus take the id of that
    -- logger.
    SELECT LOGGER_ID INTO SON
    FROM CONF_LOGGERS C
    WHERE C.NAME = HIERAR[COUNT]
    AND C.PARENT_ID = PARENT;
   END IF;
   SET COUNT = COUNT + 1;
  END WHILE;
  
  RETURN CARDINALITY(HIERAR);
 END F_GET_LOGGER