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

:: Global variables
set continue=1
set adminInstall=1
set temporalTable=0
set v9_7=0
set retValue=0

:: Main call.
:: Checks if there is already a connection established
db2 connect > NUL
if %ERRORLEVEL% EQU 0 (
 call:init %1 %2 %3
) else (
 echo Please connect to a database before the execution of the installation.
 set retValue=2
)
exit /B %retValue%
goto:eof

:: Installs a given script in DB2.
:: It uses the continue global variable to stop the execution if an error occurs.
:installScript
 set script=%~1
 echo %script%
 db2 -tsf %script%
 if %ERRORLEVEL% NEQ 0 (
  set continue=0
 )
 set script=
goto:eof

:: Function that install the utility for version 10.1.
:: DB2 v10.1
:v10.1
 echo Installing utility for v10.1
 if %adminInstall% EQU 1 (
  if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\00-AdminObjects.sql
 )
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\01-Tables.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\02-UtilityHeader.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\03-UtilityBody.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\04-Appenders.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\05-LOG.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\06-GET_LOGGER.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\07-Trigger.sql

 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\08-AdminHeader.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\09-AdminBody.sql

 cd %LOG4DB2_SRC_MAIN_CODE_PATH%
 cd ..
 cd xml
 if %continue% EQU 1 call:installScript 10-AppendersXML.sql
 cd ..
 cd scripts 2> NUL

 :: Temporal capabilities for tables.
 if %temporalTable% EQU 1 if %continue% EQU 1 (
  echo Create table for Time Travel
  call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\11-TablesTimeTravel.sql
 )

 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\12-Version.sql

 set retValue=%continue%
 set continue=
goto:eof

:: Function that install the utility for version 9.7.
:: DB2 v9.7
:v9.7
 echo Installing utility for v9.7
 if %adminInstall% EQU 1 (
  if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\00-AdminObjects.sql
 )
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\01-Tables_v9_7.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\02-UtilityHeader.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\03-UtilityBody.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\04-Appenders.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\05-LOG.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\06-GET_LOGGER_v9_7.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\07-Trigger.sql

 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\08-AdminHeader.sql
 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\09-AdminBody.sql

 cd %LOG4DB2_SRC_MAIN_CODE_PATH%
 cd ..
 cd xml
 if %continue% EQU 1 call:installScript 10-AppendersXML.sql
 cd ..
 cd scripts 2> NUL

 if %continue% EQU 1 call:installScript %LOG4DB2_SRC_MAIN_CODE_PATH%\12-Version.sql

 set retValue=%continue%
 set continue=
goto:eof

:: This functions checks all parameters and assign them to global variables.
:checkParam
 set param1=%1
 set param2=%2
 set param3=%3
 if /I "%param1%" == "-A" (
  set adminInstall=0
 )
 if /I "%param2%" == "-A" (
  set adminInstall=0
 )
 if /I "%param3%" == "-A" (
  set adminInstall=0
 )
 if /I "%param1%" == "-t" (
  set temporalTable=1
 )
 if /I "%param2%" == "-t" (
  set temporalTable=1
 )
 if /I "%param3%" == "-t" (
  set temporalTable=1
 )
 if /I "%param1%" == "-v9_7" (
  set v9_7=1
 )
 if /I "%param2%" == "-v9_7" (
  set v9_7=1
 )
 if /I "%param3%" == "-v9_7" (
  set v9_7=1
 )
 set param1=
 set param2=
 set param3=
goto:eof

:: Main function that starts the installation.
:init
 :: Initialize the environment.
 if EXIST init.bat (
  call init.bat
 )

 echo log4db2 is licensed under the terms of the Simplified-BSD license

 :: Check the given parameters.
 call:checkParam %1 %2 %3

 :: Checks in which DB2 version the utility will be installed.
 :: DB2 v10.1 is the default version.
 if %v9_7% EQU 1 (
  call:v9.7
 ) else (
  call:v10.1
 )

 echo Please visit the wiki to learn how to use and configure this utility
 echo https://github.com/angoca/log4db2/wiki
 echo To report an issue or provide feedback, please visit:
 echo https://github.com/angoca/log4db2/issues
 echo.
 if %retValue% EQU 1 (
  echo log4db2 was successfully installed
  db2 -x "values 'Database: ' || current server"
  db2 -x "values 'Version: ' || logger.version"
  db2 -x "select 'Schema: ' || base_moduleschema from syscat.modules where moduleschema = 'SYSPUBLIC' and modulename = 'LOGGER'"
  set retValue=0
 ) else (
  echo "Check the error(s) and reinstall the utility"
  set retValue=1
 )

 :: Clean environment.
 set v9_7=
 set adminInstall=
 set temporalTable=
 if EXIST uninit.bat (
  call uninit.bat
 )
goto:eof

