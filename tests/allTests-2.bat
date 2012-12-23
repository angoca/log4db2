db2 DELETE FROM LOGDATA.LOGS

db2 -td@ -f tests\TestsAppenders.sql
db2 -td@ -f tests\TestsCascadeCallLimit.sql
db2 -td@ -f tests\TestsConfAppenders.sql
db2 -td@ -f tests\TestsConfiguration.sql
db2 -td@ -f tests\TestsConfLoggers.sql
db2 -td@ -f tests\TestsConfLoggersDelete.sql
db2 -td@ -f tests\TestsConfLoggersEffective.sql
db2 -td@ -f tests\TestsFunctionGetDefinedParentLogger.sql
db2 -td@ -f tests\TestsGetLogger.sql
db2 -td@ -f tests\TestsLevels.sql

db2 COMMIT

db2 "CALL LOGADMIN.LOGS(min_level=>4, qty=>300)"