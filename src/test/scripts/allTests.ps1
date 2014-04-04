# Copyright (c) 2012 - 2014, Andres Gomez Casanova (AngocA)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

if ( Test-Path -Path init-dev.ps1 -PathType Leaf ) {
  .\init-dev.ps1
}

echo "Executing all tests with pauses in between."

Write-Host "(next TestsAppenders)"
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsAppenders.sql
Write-Host "Press enter to continue (next TestsCache)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsCache.sql
Write-Host "Press enter to continue (next TestsCascadeCallLimit)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsCascadeCallLimit.sql
Write-Host "Press enter to continue (next TestsConfAppenders)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsConfAppenders.sql
Write-Host "Press enter to continue (next TestConfiguration)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsConfiguration.sql
Write-Host "Press enter to continue (next TestsConfLoggers)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsConfLoggers.sql
Write-Host "Press enter to continue (next TestsConfLoggersDelete)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsConfLoggersDelete.sql
Write-Host "Press enter to continue (next TestsConfLoggersEffective)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsConfLoggersEffective.sql
Write-Host "Press enter to continue (next TestsFunctionsGetDefinedParentLogger)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\cleanTriggers.ps1
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsFunctionGetDefinedParentLogger.sql
& .\${SRC_TEST_SCRIPT_PATH}\createTriggers.ps1
Write-Host "Press enter to continue (next TestsGetLogger)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsGetLogger.sql
Write-Host "Press enter to continue (next TestsGetLoggerName)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsGetLoggerName.sql
Write-Host "Press enter to continue (next TestsHierarchy)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsHierarchy.sql
Write-Host "Press enter to continue (next TestsLayout)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsLayout.sql
Write-Host "Press enter to continue (next TestsLevels)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsLevels.sql
Write-Host "Press enter to continue (next TestsLogs)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsLogs.sql
Write-Host "Press enter to continue (next TestsMessages)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
& .\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsMessages.sql
Write-Host "Press enter to continue (next TestsReferences)"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
&.\${SRC_TEST_SCRIPT_PATH}\test.ps1 ${SRC_TEST_CODE_PATH}\TestsReferences.sql

