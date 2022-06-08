/*
Copyright (c) 2013 - 2022, Andres Gomez Casanova (AngocA)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


/**
 * Installs all scripts of the utility.
 *
 * Version: 2022-05-21 v1
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

PROMPT 00-AdminObjects.sql
@@ sql-pl/00-AdminObjects.sql
PROMPT 05-Tables.sql
@@ sql-pl/05-Tables.sql
PROMPT 10-LogsTable.sql
@@ sql-pl/10-LogsTable.sql
PROMPT 15-UtilityHeader.sql
@@ sql-pl/15-UtilityHeader.sql
PROMPT 20-UtilityBody.sql
set sqlterminator @
@@ sql-pl/20-UtilityBody.sql
PROMPT 25-Appenders.sql
@@ sql-pl/25-Appenders.sql
PROMPT 30-Log.sql
@@ sql-pl/30-Log.sql
PROMPT 35-Get_Logger.sql
@@ sql-pl/35-Get_Logger.sql
PROMPT 40-Trigger.sql
@@ sql-pl/40-Trigger.sql

PROMPT 50-AdminHeader.sql
set sqlterminator ;
@@ sql-pl/50-AdminHeader.sql
PROMPT 55-AdminBody.sql
set sqlterminator @
@@ sql-pl/55-AdminBody.sql

PROMPT 65-Version.sql
@@ sql-pl/65-Version.sql

