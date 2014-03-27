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
:: Version: 2014-02-14 1-Beta
:: Author: Andres Gomez Casanova (AngocA)
:: Made in COLOMBIA.

set continue=1

:: Checks if there is already a connection established
db2 connect > NUL
if %ERRORLEVEL% EQU 0 (
 call:version %1 %2
) else (
 echo Please connect to a database before the execution of the installation.
)
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
 echo "Installing utility for v10.1"
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\Tables.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\UtilityHeader.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\UtilityBody.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\AdminHeader.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\AdminBody.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\Appenders.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\LOG.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\GET_LOGGER.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\Trigger.sql

 :: Temporal capabilities for tables.
 if "%1" EQU "t" if %continue% EQU 1 (
  echo "Create table for Time Travel"
  call:installScript %SRC_MAIN_CODE_PATH%\TablesTimeTravel.sql
 )

 if %continue% EQU 1 (
  echo "log4db2 was installed successfully"
 ) else (
  echo "Check the error(s) and reinstall the utility"
 )
goto:eof

:: DB2 v9.7
:v9.7
 echo "Installing utility for v9.7"
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\Tables_v9_7.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\UtilityHeader.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\UtilityBody.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\AdminHeader.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\AdminBody.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\Appenders.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\LOG.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\GET_LOGGER.sql
 if %continue% EQU 1 call:installScript %SRC_MAIN_CODE_PATH%\Trigger.sql

 if %continue% EQU 1 (
  echo "log4db2 was installed successfully"
 ) else (
  echo "Check the error(s) and reinstall the utility"
 )
goto:eof

:version
 if EXIST init.bat (
  call init.bat
 )

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
goto:eof

