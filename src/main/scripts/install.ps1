# Copyright (c) 2013 - 2014, Andres Gomez Casanova (AngocA)
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
# Version: 2014-02-14 1-RC
# Author: Andres Gomez Casanova (AngocA)
# Made in COLOMBIA.

${Script:continue}=1

# Installs a given script.
function installScript($script) {
 echo $script
 db2 -tsf ${script}
 if ( $LastExitCode -ne 0 ) {
  ${Script:continue}=0
 }
}

# DB2 v10.1.
function v10.1($p1) {
 echo "Installing utility for v10.1"
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\Tables.sql }
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\UtilityHeader.sql }
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\UtilityBody.sql }
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\Appenders.sql }
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\LOG.sql }
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\GET_LOGGER.sql }
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\Trigger.sql }

 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\AdminHeader.sql }
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\AdminBody.sql }

 cd ${SRC_MAIN_CODE_PATH}
 cd ..
 cd xml
 if ( ${Script:continue} ) { installScript AppendersXML.sql }
 cd ..
 cd scripts 2>&1 | Out-Null

 # Temporal capabilities for tables.
 if ( ( ${p1} -eq "t" ) -and ( ${Script:continue} ) ) {
  echo "Create table for Time Travel"
  installScript ${SRC_MAIN_CODE_PATH}/TablesTimeTravel.sql
 }

 if ( ${Script:continue} ) {
  echo "log4db2 was installed successfully"
 } else {
  echo "Check the error(s) and reinstall the utility"
 }
}

# DB2 v9.7
function v9.7() {
 echo "Installing utility for DB2 v9.7"
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\Tables_v9_7.sql }
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\UtilityHeader.sql }
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\UtilityBody.sql }
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\AdminHeader.sql }
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\LOG.sql }
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\GET_LOGGER_v9_7.sql }
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\Trigger.sql }

 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\AdminBody.sql }
 if ( ${Script:continue} ) { installScript ${SRC_MAIN_CODE_PATH}\Appenders.sql }

 cd ${SRC_MAIN_CODE_PATH}
 cd ..
 cd xml
 if ( ${Script:continue} ) { installScript AppendersXML.sql }
 cd ..
 cd scripts | Out-Null

  if ( ${Script:continue} ) {
  echo "log4db2 was installed successfully"
 } else {
  echo "Check the error(s) and reinstall the utility"
 }
}

function version($p1, $p2) {
 if ( Test-Path -Path init.ps1 -PathType Leaf ) {
  .\init.ps1
 }

 # Checks in which DB2 version the utility will be installed.
 # DB2 v10.1 is the default version.
 if ( ! ( ${p1} ) ) {
  v10.1
 } elseif ( ${p1} -eq "t" ) {
  v10.1 t
 } elseif ( ${p1} -eq "-v10_1" ) {
  if ( ! ( ${p2} ) ) {
   v10.1
  } elseif ( ${p2} -eq "t" ) {
   v10.1 t
  } else {
   echo ERROR
  }
 } elseif ( ${p1} -eq "-v9_7" ) {
  v9.7
 } else {
  echo ERROR
 }
}

# Checks if there is already a connection established
db2 connect | Out-Null
if ( $LastExitCode -eq 0 ) {
 version $Args[0] $Args[1]
} else {
 echo "Please connect to a database before the execution of the installation."
 echo "Load the DB2 profile with: set-item -path env:DB2CLP -value `"**`$$**`""
}

