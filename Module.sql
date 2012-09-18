-- Module for all code for the logger utility.
CREATE OR REPLACE MODULE logger;

-- Public functions and procedures.
-- Procedure to write logs.
ALTER MODULE logger PUBLISH
 PROCEDURE log (
  IN loggerId ANCHOR logger.conf_loggers.logger_id,
  IN levelId ANCHOR logger.levels.level_id,
  IN message ANCHOR logger.logs.message
 );
  
-- Function to register the logger.
ALTER MODULE logger PUBLISH
 FUNCTION get_logger (
  IN name VARCHAR(64)
 ) RETURNS ANCHOR logger.conf_loggers.logger_id;