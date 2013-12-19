log4db2
=======

This is a logger utility specially designed for DB2 for LUW, that uses mainly
SQL instructions with SQL PL code inside Stored Procedures.

The main objective is to provide an easy way to write messages from a stored
procedure. These messages could be queried to see the progress of a process.
This utility aims to reduce the time developping, debugging and monitoring, by
centralizing the messages produced by the code.

This utility / framework is based on the popular Java logger frameworks, 
such as log4j and slf4j/logback.

The utility is licensed with BSD 2-Clause license and the documentation is
licensed under FreeBSD Documentation license. This means you are free to use,
modify and distribute.

Installation
------------

The code is distributed according to the Maven's Standard Diretory Layout. This
allows to developers (Specifically Java developers) to identify where each
component is storedm folliwing the pattern Convention over Configuration.

NOTE: At the moment, the only way to install the utility is from the source
code. This is because the project is in a very early state, and it is
improved constantly.

4 variables need to the specified in order to run the install and test scripts.
 * SRC_MAIN_CODE_PATH
 * SRC_MAIN_SCRIPT_PATH
 * SRC_TEST_CODE_PATH
 * SRC_TEST_SCRIPT_PATH
These variables are initialized via the init script.

Before installing the scripts in a database, a connection to it has to be
established. If not, an error will be raised.

>> Windows:

cd src\main\scripts
init.bat
install.bat

>> Linux/UNIX:

cd src/main/scripts
. ./init
. ./install

Make sure to put the dot before the command. This will source the values and
use the current connection.

After the install, all statements should have been successful.



ER Model
--------

The utility  uses a set of tables to store the messages and the configuration.
This is the diagram of the entity/relation diagram.

First line: Table's name
# Primary key (mandatory.)
* Mandatory field.
o Optiontal field.

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

 +----------------------+ +------------------+ +-------------+
 | CONF_APPENDER_HIST   | | CONF_LOGGER_HIST | | LOG_HIST    |
 | # REF_ID             | | # LOGGER_ID      | | * DATE      |
 | * NAME               | | * NAME           | | o LEVEL_ID  |
 | * APPENDER_ID        | | o PARENT_ID      | | o LOGGER_ID |
 | o CONFIGURATION      | | o LEVEL_ID       | | * MESSAGE   |
 | * PATTERN            | | * BUS_START      | | * SYS_START |
 | * BUS_START          | | * BUS_END        | | * SYS_END   |
 | * BUS_END            | | * SYS_START      | +-------------+
 | * SYS_START          | | * END_START      |
 | * END_START          | | * TS_ID          |
 | * TS_ID              | +------------------+
 +----------------------+

Remember that the real names of the tables are in plural, but in a E/R diagram
are in singular.

All these tables except LOGS are in the LOGGER_SPACE tablespace. LOGS is in the
LOG_DATA_SPACE that has different characteristic to improve performance while
writing. The tablespace with 8KB page size was selected because it could
contain minimum 29 rows (when the message uses the full capacity), and a
maximum of 255 when the messages are very short.

The LOG_HIST table is created like LOGS, but at that time, two more columns are
added in order to enable the temporal capabilities.

In a similar way, the CONF_LOGGER_HIST is created like CONF_LOGGERS, but the
extra columns are added when the temporal capabilities are enabled.


