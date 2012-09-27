SET CURRENT SCHEMA LOGGER@

CREATE OR REPLACE TRIGGER CHECK_CONF_LOGGER_EFFECTIVE
BEFORE INSERT ON CONF_LOGGERS
REFERENCING NEW AS N
FOR EACH ROW
BEGIN ATOMIC
DECLARE EXISTING_ID SMALLINT;
-- Retrieves the current ID from the effective table.
-- QUE: Select Into is not allowed here, and I do not know why.
SET EXISTING_ID = (SELECT LOGGER_ID
  FROM CONF_LOGGERS_EFFECTIVE E
  WHERE E.LOGGER_ID = N.LOGGER_ID);
-- Checks if the id exists in the effective table.
IF (EXISTING_ID IS NULL) THEN
 -- It does not exist, then raise a signal.
 SIGNAL SQLSTATE VALUE 'LG001'
        SET MESSAGE_TEXT = 'Logger not defined in Effective table'; 
END IF;
END@

