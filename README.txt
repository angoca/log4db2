log4db2

This is a logger utility specially designed for DB2 UDB, that uses mainly SQL
instructions with PL SQL code inside Stored Procedures.

The main objective is to provide an easy way to write messages from a
stored procedure and then track them to see the progress.

This utility / framework is based on the popular Java logger frameworks, 
such as log4j and slj4j/logback.

The utility is licensed with BSD license.

The data model is the next:

      ++==============================---------------+
      ||                                             A
+------------+             +-------------+  +-----------------------+
| LEVEL      |             | CONF_LOGGER |  | CONF_LOGGER_EFFECTIVE |
| # LEVEL_ID |======- - - <| # LOGGER_ID |  | # LOGGER_ID           |
| * NAME     |             | * NAME      |  | * NAME                |
+------------+        + - <| o PARENT_ID |  | o PARENT_ID           |
                      '    | o LEVEL_ID  |  | * LEVEL_ID            |> - +
                      '    +-------------+  +-----------------------+    '
                      '     ||    ||                           ||        '
                      '     ||    ||                           ||        '
                      +=====++    '                            ++========+ 
                                  '
                                 -A-
                           +-------------------+
                           | REFERENCE         |
                           | # LOGGER_ID       |
                           | # APPENDER_REF_ID |
                           +-------------------+
                                 -V-
                                  ''
                                  ''
                                  ||
                                  ||
                          +-----------------+
+---------------+         | CONF_APPENDER   |
| APPENDER      |         | # REF_ID        |
| # APPENDER_ID |====- - <| * NAME          |
| * NAME        |         | * APPENDER_ID   |
*---------------+         | o CONFIGURATION |
                          | * PATTERN       |
                          +-----------------+

+---------------+
| CONFIGURATION |
| # KEY         |
| o VALUE       |
+---------------+

+-------------+
| LOG         |
| * DATE      |
| o LEVEL_ID  |
| o LOGGER_ID |
| * MESSAGE   |
+-------------+

All these tables except LOGS are in the LOGGER_SPACE tablespace. LOGS is in the
LOG_DATA_SPACE that has different characteristic to improve performance while
writing. The tablespace with 8KB page size was selected because it could contain
minimum 29 rows (when the message uses the full capacity), and a maximum of
255 when the messages are very short.