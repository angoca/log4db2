@echo off
:: Copyright (c) 2012 - 2013, Andres Gomez Casanova (AngocA)
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

if EXIST init.bat call init.bat
db2 DELETE FROM LOGDATA.LOGS

echo Executing all tests.
echo on

db2 -td@ -f %SRC_TEST_CODE_PATH%\TestsAppenders.sql
db2 -td@ -f %SRC_TEST_CODE_PATH%\TestsCache.sql
db2 -td@ -f %SRC_TEST_CODE_PATH%\TestsCascadeCallLimit.sql
db2 -td@ -f %SRC_TEST_CODE_PATH%\TestsConfAppenders.sql
db2 -td@ -f %SRC_TEST_CODE_PATH%\TestsConfiguration.sql
db2 -td@ -f %SRC_TEST_CODE_PATH%\TestsConfLoggers.sql
db2 -td@ -f %SRC_TEST_CODE_PATH%\TestsConfLoggersDelete.sql
db2 -td@ -f %SRC_TEST_CODE_PATH%\TestsConfLoggersEffective.sql
db2 -td@ -f %SRC_TEST_CODE_PATH%\TestsFunctionGetDefinedParentLogger.sql
db2 -td@ -f %SRC_TEST_CODE_PATH%\TestsGetLogger.sql
db2 -td@ -f %SRC_TEST_CODE_PATH%\TestsLevels.sql

@echo off
db2 COMMIT

db2 "CALL LOGADMIN.LOGS(min_level=>4, qty=>300)"


