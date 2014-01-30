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

Andres Gomez Casanova (AngocA)
@angoca


Installation
------------

2 variables need to the specified in order to run the install and example
scripts.
 * SRC_MAIN_CODE_PATH
 * SRC_MAIN_SCRIPT_PATH
These variables are initialized via the init script.

Before installing the scripts in a database, a connection to it has to be
established. If not, an error will be raised.

>> Windows:

* unzip the file log4db2.zip
cd log4db2
init.bat
install.bat

>> Linux/UNIX:

tar -zxvf log4db2.tar.gz
cd log4db2
. ./init
. ./install

Make sure to put the dot before the command. This will source the values and
use the current connection.

After the install, all statements should have been successful.


Installation from Source Code
-----------------------------

The code is distributed according to the Maven's Standard Directory Layout.
This allows to developers (Specifically Java developers) to identify where each
component is stored following the pattern Convention over Configuration.

This instruction describe how to install the application from the source code.

4 variables need to the specified in order to run the install and test scripts.
 * SRC_MAIN_CODE_PATH
 * SRC_MAIN_SCRIPT_PATH
 * SRC_TEST_CODE_PATH
 * SRC_TEST_SCRIPT_PATH
These variables are initialized via the init-dev script.

Before installing the scripts in a database, a connection to it has to be
established. If not, an error will be raised.

>> Windows:

cd src\main\scripts
init-dev.bat
install.bat

>> Linux/UNIX:

cd src/main/scripts
. ./init-dev
. ./install

Make sure to put the dot before the command. This will source the values and
use the current connection.

After the install, all statements should have been successful.


Configuration
-------------

These are the configuration parameters in the LOGDATA.CONFIGURATION table.

defaultRootLevelId: This parameter defines the default level for the root
    logger. If a given logger does not have a define level, and root logger
    is neither defined, this value will be taken into account.
internalCache: This value switches the cache on/off. The caches reduces the
    select operations by querying an array where the logger configuration is
    stored, instead of querying this each time a call is issued.
logInternals: Activates the framework internal logging. This is most used for
    debugging process.
secondsToRefresh: Determines the configuration refresh frequency in seconds.
    The configuration could be modified at any time, and it wil be reloaded.
checkHierarchy: Checks the configuration defined in the CONF_LOGGERS table
    before load it. TODO This feature has not been yet implemented.
checkLevels: Checks the configruation defined in the LEVELS table before load
    it. TODO This feature has not been yet implemented.


Appenders
---------

There are different types of appenders to log the events in differents
mechanisms, each on with a different configuration. Each configuration has
also a name:

Pure SQL PL - Tables: Writes the log messages directly in the LOG table. This
    is a pure SQL PL implementation, and it works perfectly in DB2 Express-C
    edition.
db2diag.log: The log messages are written in the DB2 DIAG file. This uses the
    db2AdminMsgWrite function to write in that file. In order to activate this
    function, it is necessary to put the compiled C file in the DB2 binaries.
    TODO This functions has not been yet implemented.
UTL_FILE: The log messages are written in an external file. This uses the
    built-in functions with the same name. This does not work when using DB2
    Express-C edition. TODO This function has not been yet implemented.
DB2 logger: This uses the existant logging facility for DB2 written in C. This
    makes this framework like a wrapper. This mechanism need the installation
    of that framework before using this facility. TODO This feature has not
    been yet implemented.
Java logger: This mechanism sends the messages to a Java Stored Procedure.
    Depending on the Java Stored Procedure, and if there is a log4j or slf4j
    configuration the logs will be written into files, or other mechanisms.
    TODO This functions has not been yet implemented.

The appenders has

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


