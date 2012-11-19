
:: Checks in which DB2 version the utility will be installed.
:: DB2 v10.1 is the default version.
if "%1" EQU "" goto v10.1
if /I "%1" EQU "-v10.1" goto v10.1
if /I "%1" EQU "-v9.7" goto v9.7

:: DB2 v10.1.
:v10.1
db2 -tf Tables.sql
db2 -tf Objects.sql
db2 -td@ -f Tools.sql
db2 -td@ -f AdminHeader.sql
db2 -td@ -f AdminBody.sql
db2 -td@ -f LOG.sql
db2 -td@ -f GET_LOGGER.sql
db2 -td@ -f Trigger.sql
goto exit

:: DB2 v9.7
:v9.7
echo Installing application for DB2 v9.7
db2 -tf Tables.sql
db2 -tf Objects.sql
db2 -td@ -f Tools.sql
db2 -td@ -f AdminHeader.sql
db2 -td@ -f AdminBody.sql
db2 -td@ -f LOG.sql
db2 -td@ -f GET_LOGGER_v9_7.sql
db2 -td@ -f Trigger.sql
goto exit

:exit