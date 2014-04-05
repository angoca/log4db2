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

call init-dev.bat
db2 connect > NUL
if %ERRORLEVEL% NEQ 0 (
 echo Please connect to a database before the execution of the tests
) else (
 echo Executing all tests with pauses in between.

 echo (next TestsAppenders)
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsAppenders.sql
 echo (TestsCache)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsCache.sql
 echo (TestsCascadeCallLimit)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsCascadeCallLimit.sql
 echo (TestsConfAppenders)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsConfAppenders.sql
 echo (TestsConfiguration)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsConfiguration.sql
 echo (TestsConfLoggers)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsConfLoggers.sql
 echo (TestsConfLoggersDelete)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsConfLoggersDelete.sql
 echo (TestsConfLoggersEffective)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsConfLoggersEffective.sql
 echo (TestsFunctionGetDefinedParentLogger)
 pause
 db2 -tf %SRC_MAIN_CODE_PATH%\CleanTriggers.sql +O
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsFunctionGetDefinedParentLogger.sql
 db2 -tf %SRC_MAIN_CODE_PATH%\Trigger.sql +O
 echo (TestsGetLogger)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsGetLogger.sql
 echo (TestsGetLoggerName)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsGetLoggerName.sql
 echo (TestsHierarchy)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsHierarchy.sql
 echo (TestsLayout)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsLayout.sql
 echo (TestsLevels)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsLevels.sql
 echo (TestsLogs)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsLogs.sql
 echo (TestsMessages)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsMessages.sql
 echo (TestsReferences)
 pause
 call %SRC_TEST_SCRIPT_PATH%\test.bat %SRC_TEST_CODE_PATH%\TestsReferences.sql
)
