# Copyright (c) 2013 - 2022, Andres Gomez Casanova (AngocA)
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

# Installs all scripts of the utility.
#
# Version: 2022-06-03 v1
# Author: Andres Gomez Casanova (AngocA)
# Made in COLOMBIA.

# Global variables
${Script:continue}=1
${Script:adminInstall}=1
${Script:temporalTable}=0
${Script:retValue}=0

# Installs a given script in DB2.
# It uses the continue global variable to stop the execution if an error occurs.
function installScript($script) {
 echo $script
 db2 -tsf ${script}
 if ( $LastExitCode -ne 0 ) {
  ${Script:continue}=0
 }
}

# Function that install the utility for Db2 10.1 or higher.
function v10.1($p1) {
 echo "Installing utility for Db2 v10.1 or higher..."
 if ( ${Script:adminInstall} ) {
  if ( ${Script:continue} ) { installScript ${LOG4DB2_SRC_MAIN_CODE_PATH}\00-AdminObjects.sql }
 }
 if ( ${Script:continue} ) { installScript ${LOG4DB2_SRC_MAIN_CODE_PATH}\05-Tables.sql }
 if ( ${Script:continue} ) { installScript ${LOG4DB2_SRC_MAIN_CODE_PATH}\10-LogsTable.sql }
 if ( ${Script:continue} ) { installScript ${LOG4DB2_SRC_MAIN_CODE_PATH}\15-UtilityHeader.sql }
 if ( ${Script:continue} ) { installScript ${LOG4DB2_SRC_MAIN_CODE_PATH}\20-UtilityBody.sql }
 if ( ${Script:continue} ) { installScript ${LOG4DB2_SRC_MAIN_CODE_PATH}\25-Appenders.sql }
 if ( ${Script:continue} ) { installScript ${LOG4DB2_SRC_MAIN_CODE_PATH}\30-Log.sql }
 if ( ${Script:continue} ) { installScript ${LOG4DB2_SRC_MAIN_CODE_PATH}\35-Get_Logger.sql }
 if ( ${Script:continue} ) { installScript ${LOG4DB2_SRC_MAIN_CODE_PATH}\40-Trigger.sql }

 cd ${LOG4DB2_SRC_MAIN_CODE_PATH}
 cd ..
 cd xml
 if ( ${Script:continue} ) { installScript 45-AppendersXML.sql }
 cd ..
 cd scripts 2>&1 | Out-Null

 if ( ${Script:continue} ) { installScript ${LOG4DB2_SRC_MAIN_CODE_PATH}\50-AdminHeader.sql }
 if ( ${Script:continue} ) { installScript ${LOG4DB2_SRC_MAIN_CODE_PATH}\55-AdminBody.sql }

 # Temporal capabilities for tables.
 if ( ( ${Script:temporalTable} ) -and ( ${Script:continue} ) ) {
  echo "Create table for Time Travel"
  installScript ${LOG4DB2_SRC_MAIN_CODE_PATH}\60-TablesTimeTravel.sql
 }

 if ( ${Script:continue} ) { installScript ${LOG4DB2_SRC_MAIN_CODE_PATH}\65-Version.sql }
}

# This function checks all parameters and assign them to global variables.
function checkParam($p1, $p2, $p3) {
 $param1=${p1}
 $param2=${p2}
 $param3=${p3}
 if ( "${param1}" -eq "-A" -or "${param2}" -eq "-A" -or "${param3}" -eq "-A" ) {
  ${Script:adminInstall}=0
 }
 if ( "${param1}" -eq "-t" -or "${param2}" -eq "-t" -or "${param3}" -eq "-t" ) {
  ${Script:temporalTable}=1
 }
}

# Main unction that starts the installation.
function init($p1, $p2, $p3) {
 if ( Test-Path -Path init.ps1 -PathType Leaf ) {
  .\init.ps1
 }

 echo "log4db2 is licensed under the terms of the Simplified-BSD license"

 # Check the given parameters.
 checkParam ${p1} ${p2} ${p3}

 # Checks in which DB2 version the utility will be installed.
 v10.1

 echo "Please visit the wiki to learn how to use and configure this utility"
 echo "https://github.com/angoca/log4db2/wiki"
 echo "To report an issue or provide feedback, please visit:"
 echo "https://github.com/angoca/log4db2/issues"
 echo ' '
 if ( ${Script:continue} ) {
  echo "log4db2 was successfully installed"
  db2 -x "values 'Database: ' || current server"
  db2 -x "values 'Version: ' || logger.version"
  db2 -x "select 'Schema: ' || base_moduleschema from syscat.modules where moduleschema = 'SYSPUBLIC' and modulename = 'LOGGER'"
  ${Script:retValue}=0
 } else {
  echo "Check the ERROR(s) and reinstall the utility"
  echo "For more information visit check the FAQs:"
  echo "https://github.com/angoca/log4db2/wiki/FAQs"
  echo "You can also check the install guide:"
  echo "https://github.com/angoca/log4db2/wiki/Install"
  ${Script:retValue}=1
 }

 # Clean environment.
 if ( Test-Path -Path uninit.ps1 -PathType Leaf ) {
  .\uninit.ps1
 }
}

# Checks if there is already a connection established
db2 connect | Out-Null
if ( $LastExitCode -eq 0 ) {
 init $Args[0] $Args[1] $Args[2]
} else {
 echo "Please connect to a database before the execution of the installation."
 echo "Load the DB2 profile with: set-item -path env:DB2CLP -value `"**`$$**`""
 ${Script:retValue}=2
}

exit ${Script:retValue}

