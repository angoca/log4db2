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

:: Installs all scripts of the utility.
::
:: Version: 2014-02-14 1-RC
:: Author: Andres Gomez Casanova (AngocA)
:: Made in COLOMBIA.

set continue=1
set retValue=0

:: Checks if there is already a connection established
db2 connect > NUL
if %ERRORLEVEL% EQU 0 (
 call:init %1 %2
) else (
 echo Please connect to a database before the execution of the installation.
 set retValue=2
)
exit /B %retValue%
goto:eof

:: Installs a given script.
:installScript
 set script=%~1
 echo %script%
 db2 -tsf %script%
 if %ERRORLEVEL% NEQ 0 (
  set continue=0
 )
goto:eof

:: DB2 v10.1
:v10.1
 echo Installing utility for v10.1
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\AdminObjects.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\Tables.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\UtilityHeader.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\UtilityBody.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\Appenders.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\LOG.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\GET_LOGGER.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\Trigger.sql

 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\AdminHeader.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\AdminBody.sql

 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\Version.sql

 cd %LOG4DB2_SRC_MAIN_CODE_PATH%
 cd ..
 cd xml
 if %continue% EQU 1 call:installScript AppendersXML.sql
 cd ..
 cd scripts 2> NUL

 :: Temporal capabilities for tables.
 if "%1" EQU "t" if %continue% EQU 1 (
  echo Create table for Time Travel
  call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\TablesTimeTravel.sql
 )

 echo Please visit the wiki to learn how to use and configure this utility
 echo https://github.com/angoca/log4db2/wiki
 echo To report an issue or provide feedback, please visit:
 echo https://github.com/angoca/log4db2/issues
 echo.
 if %continue% EQU 1 (
  echo log4db2 was successfully installed
  db2 -x "values 'Database: ' || current server"
  db2 -x "values 'Version: ' || logger.version"
  db2 -x "select 'Schema: ' || base_moduleschema from syscat.modules where moduleschema = 'SYSPUBLIC' and modulename = 'LOGGER'"
  set retValue=0
 ) else (
  echo "Check the error(s) and reinstall the utility"
  set retValue=1
 )
goto:eof

:: DB2 v9.7
:v9.7
 echo Installing utility for v9.7
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\AdminObjects.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\Tables_v9_7.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\UtilityHeader.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\UtilityBody.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\Appenders.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\LOG.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\GET_LOGGER_v9_7.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\Trigger.sql

 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\AdminHeader.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\AdminBody.sql

 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\Version.sql

 cd %LOG4DB2_SRC_MAIN_CODE_PATH%
 cd ..
 cd xml
 if %continue% EQU 1 call:installScript AppendersXML.sql
 cd ..
 cd scripts 2> NUL

 echo Please visit the wiki to learn how to use and configure this utility
 echo https://github.com/angoca/log4db2/wiki
 echo To report an issue or provide feedback, please visit:
 echo https://github.com/angoca/log4db2/issues
 echo.
 if %continue% EQU 1 (
  echo log4db2 was successfully installed
  db2 -x "values 'Database: ' || current server"
  db2 -x "values 'Version: ' || logger.version"
  db2 -x "select 'Schema: ' || base_moduleschema from syscat.modules where moduleschema = 'SYSPUBLIC' and modulename = 'LOGGER'"
  set retValue=0
 ) else (
  echo "Check the error(s) and reinstall the utility"
  set retValue=1
 )
goto:eof

:init
 if EXIST init.bat (
  call init.bat
 )

 echo log4db2 is licensed under the terms of the Simplified-BSD license

 :: Checks in which DB2 version the utility will be installed.
 :: DB2 v10.1 is the default version.
 if "%1" EQU "" (
  call:v10.1
 ) else if /I "%1" EQU "t" (
  call:v10.1 t
 ) else if /I "%1" EQU "-v10.1" (
  if /I "%2" EQU "" (
   call:v10.1
  ) else if /I "%2" EQU "t" (
   call:v10.1 t
  ) else (
   echo ERROR
  )
 ) else if /I "%1" EQU "-v9.7" (
  call:v9.7
 ) else (
  echo ERROR
 )

 if EXIST uninit.bat (
  call uninit.bat
 )
goto:eof

