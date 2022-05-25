# log4db2 #
-----------

Log4db2 is a logging utility for DB2 for LUW that uses SQL instructions with SQL
PL code.

Its purpose is to provide an easy way to write messages from a SQL routine, with
the possibility to query these messages directly from the database, allowing to monitor the progression of a process.
This utility aims to reduce the time used for developing, testing, debugging and 
monitoring SQL routines, by centralizing the messages produced by the code.

The idea and architecture of this utility are based on the popular Java logging
utilities, such as Log4j and slf4j/logback.

 * [Log4j](http://logging.apache.org/log4j).
 * [Logback/SLF4J](http://logback.qos.ch/ [http://www.slf4j.org/).

The licenses of this project are:

  * For the source code is "BSD 2-Clause license".
  * For the documentation is "FreeBSD Documentation license."
 
With these two licenses you are free to use, modify and distribute any part of this
utility.

Author:

Andres Gomez Casanova (@angoca)


------------------
## Links for more information ##

These are some useful links:

 * The source code is hosted at:
    [https://github.com/angoca/log4db2](https://github.com/angoca/log4db2)
 * The wiki is at:
    [https://github.com/angoca/log4db2/wiki](https://github.com/angoca/log4db2/wiki)
 * The last released version is published at:
    [https://github.com/angoca/log4db2/releases](https://github.com/angoca/log4db2/releases)
 * The issue tracker is at:
    [https://github.com/angoca/log4db2/issues](https://github.com/angoca/log4db2/issues)
 * A blog that explain things about this utility:
    [http://angocadb2.blogspot.com/](https://angocadb2.blogspot.com/2012/06/log4db2-logging-in-sql-pl-db2.html)


------------------
## Installation ##

One variable needs to the specified in order to run the install and example
scripts.

    LOG4DB2_PATH

This variable is initialized via the `init` script.

Before installing the scripts in a database, a connection to it has to be
established. If not, an error will be raised.

**Linux/UNIX/MAC OS**:

Just follow these steps:

    tar -zxvf log4db2.tar.gz
    cd log4db2
    . ./install

Make sure to put the dot (source command) before the script. This will source the
values and use the current connection.

**Windows Terminal (CMD - db2clp)**:

First, unzip the file log4db2.zip, and then:

    cd log4db2
    init.bat
    install.bat

**Windows PowerShell**:

First, unzip the file log4db2.zip, and then:

    cd log4db2
    .\init.ps1
    .\install.ps1

### Check install ###

After the install, all statements should have been successful.

A more detailed guide to install the utility can be found in the [_Install_](https://github.com/angoca/log4db2/wiki/Install)
section of the wiki.

You can also install the utility from the sources and run the examples and
tests:
[wiki/Install%20from%20sources](https://github.com/angoca/log4db2/wiki/Install%20from%20sources).

Once the utility is installed, you can customize the utility. For more
information, please visit the _configuration_ section:
[wiki/Configuration](https://github.com/angoca/log4db2/wiki/Configuration).


-----------
## Usage ##

### 1. Write the code ###

This could be the structure of your routine's code (Procedure or function).

    CREATE ... HELLO_WORLD ()
     MODIFIES SQL
     BEGIN
      DECLARE LOGGER_ID SMALLINT;
      -- Your declarations

      CALL LOGGER.GET_LOGGER('Your.Hierarchy', LOGGER_ID);
      -- Your code
      CALL LOGGER.INFO(LOGGER_ID, 'Your message');
      -- Your code
     END @

As you can see, there is a call to GET_LOGGER to register the logger, and get its
id. Then, you write messages by providing the id and the text. That's all.

### 2. Invoke the code ###

Then, you invoke your code (Depending if it is a stored procedure or a
function.)

    CALL HELLO_WORLD(); -- Stored procedure.
    VALUES HELLO_WORLD(); -- Function.

### 3. Check the results ###

This is the easiest way to check the log messages.

    CALL LOGADMIN.LOGS();

From the CLP is:

    db2 "CALL LOGADMIN.LOGS()"

Check the _Usage_ section for more information about the levels, how to access
the messages and configure the utility: 
[wiki/Usage](https://github.com/angoca/log4db2/wiki/Usage).


---------------------------
## Files and directories ##

These are the files included in the released version:

 * `COPYING.txt` -- License for the code (BSD license - OpenSource).
 * `init*` -- Environment configuration. 
 * `install*` -- Installation files.
 * `README.txt` -- This file.
 * `reinstall*` -- Reinstallation files.
 * `uninstall*` -- Uninstallation files.
 * `doc` directory -- Documentation directory (ErrorCode, ER diagram).
 * `sql-pl` directory -- Directory for all objects: DDL, DML, routines
     definition.
   * `AdminBody.sql` -- Body of the administration tools.
   * `AdminHeader.sql` -- Headers of the administration tools.
   * `Appenders.sql` -- Definition of the appenders.
   * `Appenders_No_ExpC.sql` -- Appenders for DB2 no Community/Express-C (LOG_UTL_FILE).
    This is not included in the installation.
   * `CleanObjects.sql` -- Remove all objects.
   * `CleanTables.sql` -- Remove all tables.
   * `CleanTriggers.sql` -- Remove all triggers.
   * `Get_Logger.sql` -- GetLogger procedure definition for v10.1 or upper.
   * `Get_Logger_v9_7.sql` -- GetLogger procedure definition for v9.7.
   * `Log.sql` -- Log procedure definition with its macros.
   * `Tables.sql` -- Tables, tablespaces, bufferpools, schemas, and DML.
   * `TablesTimeTravel.sql` -- Modifications for Time Travel.
   * `Tables_v9_7.sql` - Tables, tablespaces, bufferpools, schemas, and DML for
       v9.7.
   * `Trigger.sql` -- Trigger of the different tables.
   * `UtilityBody.sql` -- Body of the core tools.
   * `UtilityHeader.sql` -- Headers of the core tools.
      
 * `xml` directory -- Directory for XML Schemas, XML files and related scripts
     for appenders configuration.
   * `Appender_UTL_FILE.xml` -- Configuration for LOG_UTL_FILE appender.
   * `AppendersXML.sql` -- Registers the XML Schema.
   * `conf_appender.xsd` -- XML Schema.

The * in the install-related files means that several files for each one of
them can be found:

 * `.bat` -- Windows Batch file for CMD.exe
 * `.ps1` -- Windows PowerShell
 * `.sql` -- For DB2 CLPPlus.
 * No extension -- For Linux/UNIX/Mac OS X.

