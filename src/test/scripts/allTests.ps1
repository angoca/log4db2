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

# Execute all tests.
#
# Version: 2014-04-21 1-RC
# Author: Andres Gomez Casanova (AngocA)
# Made in COLOMBIA.

.\init-dev.ps1

db2 connect | Out-Null
if ( $LastExitCode -ne 0 ) {
 echo "Please connect to a database before the execution of the tests."
 echo "Load the DB2 profile with: set-item -path env:DB2CLP -value `"**`$$**`""
} else {
 echo "Executing all tests with pauses in between."

 Write-Host "(next LOG4DB2_APPENDERS)"
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_APPENDERS i x
 Write-Host "Press enter to continue (next LOG4DB2_APPENDERS_IMPLEMENTATION)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_APPENDERS_IMPLEMENTATION i x
 Write-Host "Press enter to continue (next LOG4DB2_CACHE_CONFIGURATION)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_CACHE_CONFIGURATION i x
 Write-Host "Press enter to continue (next LOG4DB2_CACHE_LEVELS)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_CACHE_LEVELS i x
 Write-Host "Press enter to continue (next LOG4DB2_CACHE_LOGGERS)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_CACHE_LOGGERS i x
 Write-Host "Press enter to continue (next LOG4DB2_CASCADE_CALL_LIMIT)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_CASCADE_CALL_LIMIT i x
 Write-Host "Press enter to continue (next LOG4DB2_CONF_APPENDERS)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_CONF_APPENDERS i x
 Write-Host "Press enter to continue (next LOG4DB2_CONFIGURATION)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_CONFIGURATION i x
 Write-Host "Press enter to continue (next LOG4DB2_CONF_LOGGERS)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_CONF_LOGGERS i x
 Write-Host "Press enter to continue (next LOG4DB2_CONF_LOGGERS_DELETE)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_CONF_LOGGERS_DELETE i x
 Write-Host "Press enter to continue (next LOG4DB2_CONF_LOGGERS_EFFECTIVE)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_CONF_LOGGERS_EFFECTIVE i x
 Write-Host "Press enter to continue (next LOG4DB2_CONF_LOGGERS_EFFECTIVE_CASES)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_CONF_LOGGERS_EFFECTIVE_CASES i x
 Write-Host "Press enter to continue (next LOG4DB2_DYNAMIC_APPENDERS)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_DYNAMIC_APPENDERS i x
 Write-Host "Press enter to continue (next LOG4DB2_FUNCTION_GET_DEFINED_PARENT_LOGGER)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 db2 -tf ${LOG4DB2_LOG4DB2_SRC_MAIN_CODE_PATH}/96-CleanTriggers +O
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_FUNCTION_GET_DEFINED_PARENT_LOGGER i x
 db2 -tf ${LOG4DB2_LOG4DB2_SRC_MAIN_CODE_PATH}/07-Trigger +O
 Write-Host "Press enter to continue (next LOG4DB2_GET_LOGGER)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_GET_LOGGER i x
 Write-Host "Press enter to continue (next LOG4DB2_GET_LOGGER_NAME)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_GET_LOGGER_NAME i x
 Write-Host "Press enter to continue (next LOG4DB2_HIERARCHY)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_HIERARCHY i x
 Write-Host "Press enter to continue (next LOG4DB2_LAYOUT)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_LAYOUT i x
 Write-Host "Press enter to continue (next LOG4DB2_LEVELS)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_LEVELS i x
 Write-Host "Press enter to continue (next LOG4DB2_LOGS)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_LOGS i x
 Write-Host "Press enter to continue (next LOG4DB2_MESSAGES)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 & .\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_MESSAGES i x
 Write-Host "Press enter to continue (next LOG4DB2_REFERENCES)"
 $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
 &.\${LOG4DB2_SRC_TEST_SCRIPT_PATH}\test.ps1 LOG4DB2_REFERENCES i x
}

