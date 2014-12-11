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

# Install and/or execute a suite of tests.
#
# Version: 2014-04-21 1-RC
# Author: Andres Gomez Casanova (AngocA)
# Made in COLOMBIA.

db2 connect | Out-Null
if ( $LastExitCode -ne 0 ) {
 echo "Please connect to a database before the execution of the test."
 echo "Load the DB2 profile with: set-item -path env:DB2CLP -value `"**`$$**`""
 echo "Remember that to call the script the command is '.\test <TestSuite> {i} {x}'"
 echo "i for installing (by default)"
 echo "x for executing"
 echo "The test file should have this structure: Test_<SCHEMA_NAME>.sql"
} else {
 ${SCHEMA}=$Args[0]
 ${OPTION_1}=$Args[1]
 ${OPTION_2}=$Args[2]
 # Execute the tests.
 if ( "${OPTION_1}" -eq "" -or "${OPTION_1}" -eq "i" -or "${OPTION_2}" -eq "i" ) {
  # Prepares the installation.
  db2 "DELETE FROM LOGS" | Out-Null
  db2 "DROP TABLE ${SCHEMA}.REPORT_TESTS" | Out-Null
  db2 "CALL SYSPROC.ADMIN_DROP_SCHEMA('${SCHEMA}', NULL, 'ERRORSCHEMA', 'ERRORTABLE')" | Out-Null
  db2 "SELECT VARCHAR(SUBSTR(DIAGTEXT, 1, 256), 256) AS ERROR FROM ERRORSCHEMA.ERRORTABLE" 2>&1 | Out-Null
  db2 "DROP TABLE ERRORSCHEMA.ERRORTABLE" | Out-Null
  db2 "DROP SCHEMA ERRORSCHEMA RESTRICT" | Out-Null

  # Installs the tests.
  db2 -td@ -f ${LOG4DB2_SRC_TEST_CODE_PATH}\Tests_${SCHEMA}.sql
 }

 # Execute the tests.
 if ( "${OPTION_1}" -eq "x" -or "${OPTION_2}" -eq "x" ) {
  db2 "CALL DB2UNIT.CLEAN()"
  db2 "CALL DB2UNIT.RUN_SUITE('${SCHEMA}')"
  db2 "CALL DB2UNIT.GET_LAST_EXECUTION_ORDER()"
  db2 "CALL DB2UNIT.CLEAN()"
 }

 if ( "${OPTION_1}" -eq "x" -and "${OPTION_2}" -eq "" ) {
  db2 "CALL LOGADMIN.LOGS(min_level=>5)"
  db2 "SELECT EXECUTION_ID EXEC_ID, VARCHAR(SUBSTR(TEST_NAME, 1, 32), 32) TEST,
    FINAL_STATE STATE, TIME, VARCHAR(SUBSTR(MESSAGE, 1, 128), 128)
    FROM ${SCHEMA}.REPORT_TESTS ORDER BY DATE"
 }
}

