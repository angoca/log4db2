--#SET TERMINATOR ;
SET CURRENT SCHEMA LOGGER_1A;

-- Drops all objects.
DROP MODULE LOGGER;

DROP VIEW LOG_MESSAGES;

DROP TRIGGER UNIQUE_DATE;

DROP TRIGGER CHECK_CONF_LOGGER;

DROP TRIGGER CHECK_CONF_LOGGER_EFFECTIVE;

DROP TRIGGER ROOT_LOGGER_UNDELETABLE;

DROP TRIGGER REF_ID_GREATER_EQUAL_ZERO;

DROP TRIGGER APPENDER_GREATER_EQUAL_ZERO;

DROP TRIGGER CONF_APPENDER_PATTERN;

DROP PUBLIC ALIAS LOGGER FOR MODULE;

DROP SCHEMA LOGGER_1A RESTRICT;