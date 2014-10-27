@echo off
:: Copyright (c) 2012 - 2014, Andres Gomez Casanova (AngocA)
:: All rights reserved.
::
:: Redistribution and use in source and binary forms, with or without
:: modification, are permitted provided that the following conditions are met:
::
:: 1. Redistributions of source code must retain the above copyright notice,
::    this list of conditions and the following disclaimer.
:: 2. Redistributions in binary form must reproduce the above copyright notice,
::    this list of conditions and the following disclaimer in the documentation
::    and/or other materials provided with the distribution.
::
:: THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
:: AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
:: IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
:: ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
:: LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
:: CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
:: SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
:: INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
:: CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
:: ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
:: POSSIBILITY OF SUCH DAMAGE.

:: Execute all tests.
::
:: Version: 2014-04-21 1-RC
:: Author: Andres Gomez Casanova (AngocA)
:: Made in COLOMBIA.

call init-dev.bat

db2 connect > NUL
if %ERRORLEVEL% NEQ 0 (
 echo Please connect to a database before the execution of the tests
) else (
 Setlocal EnableDelayedExpansion
 if "%1" == "-np" (
  set PAUSE=false
  set TIME_INI=echo !time!
 ) else (
  set PAUSE=true
 )
 if "!PAUSE!" == "true" (
  echo Executing all tests with pauses in between.
 ) else if "!PAUSE!" == "false" (
  echo Executing all tests.
 ) else (
  echo Error expanding variable
  exit /B -1
 )
 call:executeTest LOG4DB2_APPENDERS
 call:executeTest LOG4DB2_APPENDERS_IMPLEMENTATION
 call:executeTest LOG4DB2_CACHE_CONFIGURATION
 call:executeTest LOG4DB2_CACHE_LEVELS
 call:executeTest LOG4DB2_CACHE_LOGGERS
 call:executeTest LOG4DB2_CASCADE_CALL_LIMIT
 call:executeTest LOG4DB2_CONF_APPENDERS
 call:executeTest LOG4DB2_CONFIGURATION
 call:executeTest LOG4DB2_CONF_LOGGERS
 call:executeTest LOG4DB2_CONF_LOGGERS_DELETE
 call:executeTest LOG4DB2_CONF_LOGGERS_EFFECTIVE
 call:executeTest LOG4DB2_CONF_LOGGERS_EFFECTIVE_CASES
 call:executeTest LOG4DB2_DYNAMIC_APPENDERS
 set TEST=LOG4DB2_FUNCTION_GET_DEFINED_PARENT_LOGGER
 echo ====Next: !TEST!
 if "!PAUSE!" == "true" (
  pause
 )
 db2 -tf !LOG4DB2_SRC_MAIN_CODE_PATH!\96-CleanTriggers.sql +O
 call !LOG4DB2_SRC_TEST_SCRIPT_PATH!\test.bat !LOG4DB2_SRC_TEST_CODE_PATH!\!TEST!.sql
 db2 -tf !LOG4DB2_SRC_MAIN_CODE_PATH!\07-Trigger.sql +O
 call:executeTest LOG4DB2_GET_LOGGER
 call:executeTest LOG4DB2_GET_LOGGER_NAME
 call:executeTest LOG4DB2_HIERARCHY
 call:executeTest LOG4DB2_LAYOUT
 call:executeTest LOG4DB2_LEVELS
 call:executeTest LOG4DB2_LOGS
 call:executeTest LOG4DB2_MESSAGES
 call:executeTest LOG4DB2_REFERENCES
 if not "!PAUSE!" == "true" (
  set TIME_END=echo !time!
  echo Difference:
  echo !TIME_INI! start
  echo !TIME_END! end
 )
 Setlocal DisableDelayedExpansion
 set PAUSE=
)
goto:eof

:: Execute a given test.
:executeTest
 set schema=%~1
 echo ====Next: %schema%
 if "!PAUSE!" == "true" (
  pause
  call %LOG4DB2_SRC_TEST_SCRIPT_PATH%\test.bat %schema% i x
 ) else (
  call %LOG4DB2_SRC_TEST_SCRIPT_PATH%\test.bat %schema% x
 )
goto:eof

