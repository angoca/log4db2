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

# Performs the equivalent of "tail -f" with the LOGS table.
#
# Version: 2014-10-23 1-RC
# Author: Andres Gomez Casanova (AngocA)
# Made in COLOMBIA.

${VAL}=$Args[0]
${INC}=1
${SECONDS}=$Args[1]

if ( "${VAL}" -eq "" ) {
 $INC=0
 $VAL=2
}

if ( "${SECONDS}" -eq "" ) {
 ${SECONDS}=1
}

db2 connect | Out-Null
if ( $LastExitCode -eq 0 ) {
 ${I}=0
 while ( ${I} -le ${VAL} ) {
  db2 -x +w "call logadmin.next_logs()" | Select-String -Pattern "^  Result set 1$" -notmatch | Select-String -Pattern "^  --------------$" -notmatch | Select-String -Pattern "^  Return Status = 0$" -notmatch | Select-String -Pattern "^$" -notmatch
  if ( ${I} -ne ${VAL} ) {
   # echo "Waiting ${SECONDS} seconds..."
   Start-Sleep -s ${SECONDS}
  }
  ${I}=${I}+${INC}
 }
} else {
 echo "Please connect to a database before execute this script."
 echo "Load the DB2 profile with: set-item -path env:DB2CLP -value `"**`$$**`""
}

