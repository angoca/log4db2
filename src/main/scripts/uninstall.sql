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
 * Uninstalls all the components of this utility.
 *
 * Version: 2014-04-03 v1
 * Author: Andres Gomez Casanova (AngocA)
 * Made in COLOMBIA.
 */

PROMPT Uninstalling log4db2...
PROMPT 96-CleanTriggers.sql
@@ sql-pl/96-CleanTriggers.sql
PROMPT 97-CleanObjects.sql
@@ sql-pl/97-CleanObjects.sql
PROMPT Drop packages
@@ PACKAGES_TO_DROP_SCHEMA.sql
PROMPT 98-CleanTables.sql
@@ sql-pl/98-CleanTables.sql
PROMPT Drop packages
@@ PACKAGES_TO_DROP_SCHEMA.sql
PROMPT 99-CleanAdmin.sql
@@ sql-pl/99-CleanAdmin.sql

