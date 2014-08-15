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

:: Install and/or execute a suite of tests.
::
:: Version: 2014-04-21 1-RC
:: Author: Andres Gomez Casanova (AngocA)
:: Made in COLOMBIA.

db2 connect > NUL
if %ERRORLEVEL% NEQ 0 (
 echo Please connect to a database before the execution of the test
 echo Remember that to call the script the command is 'test <TestSuite> {i} {x}'
 echo i for installing (by default)
 echo x for executing
 echo The test file should have this structure: Test_<SCHEMA_NAME>.sql
) else (
 set SCHEMA=%1
 set OPTION_1=%2
 set OPTION_2=%3
 :: Execute the tests.
 :: if "%OPTION_1%" EQU "" -o "%OPTION_1%" EQU "i" -o "%OPTION_2%" EQU "i" (
 :: A OR B OR C = not [ not { not ( not A and not B ) } and not C ]
 if (not if (not if (not if (not "%OPTION_1%" EQU "") if (not "%OPTION_1%" EQU "i"))) if (not "%OPTION_2%" EQU "i")) (
  :: Prepares the installation.
  db2 "DELETE FROM LOGS" > NUL
  db2 "DROP TABLE %1.REPORT_TESTS" > NUL
  db2 "CALL SYSPROC.ADMIN_DROP_SCHEMA('%SCHEMA%', NULL, 'ERRORSCHEMA', 'ERRORTABLE')" > NUL
  db2 "SELECT VARCHAR(SUBSTR(DIAGTEXT, 1, 256), 256) AS ERROR FROM ERRORSCHEMA.ERRORTABLE" 2> NUL
  db2 "DROP TABLE ERRORSCHEMA.ERRORTABLE" > NUL
  db2 "DROP SCHEMA ERRORSCHEMA RESTRICT" > NUL

  :: Installs the tests.
  db2 -td@ -f ../sql-pl/Tests_%SCHEMA%.sql
 )

 :: Execute the tests.
 ::if "%OPTION_1%" EQU "x" -o "%OPTION_2%" EQU "x" (
 if (not "%OPTION_1%" EQU "x") if ("%OPTION_2%" EQU "x") (
  db2 "CALL DB2UNIT.CLEAN()"
  db2 "CALL DB2UNIT.RUN_SUITE('%SCHEMA%')"
  db2 "CALL DB2UNIT.CLEAN()"
 )

 if (not if (not if (not if (not "%OPTION_1%" EQU "") if (not "%OPTION_1%" EQU "i"))) if (not "%OPTION_2%" EQU "i")) (
  db2 "CALL LOGADMIN.LOGS(min_level=>4)"
 )
)

