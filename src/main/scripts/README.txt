The files contained in this directory allows you to perform the installation,
reinstallation and unistallation of the progam. Each script is written for
different platforms:

* Without extension: For Linux, UNIX and Mac OS.
* .bat extension: For Windows in CMD.
* .ps1 extension: For Windows in PowerShell.

These scripts works in two modes:

* Released: This mode is used by the end user. Releases are published in
the "releases" section of GitHub and they are distributed via tar and zip files.
* Development: This is used when the utility is being developed, it means,
new functionality is added or bugs are fixed. In the `src/test/scripts`
directory some extra scripts can be found to configure the environment and
for testing purposes.

# Linux/UNIX/Mac OS

## Release

Just follow these steps:

    tar -zxvf log4db2.tar.gz
    cd log4db2
    . ./init
    . ./install

Make sure to put the dot before the command. This will source the values and
use the current connection.

## Development

    cd src/test/scripts
    . ./init-dev
    cd ../../main/scripts
    . ./install

Make sure to put the dot before the command. This will source the values and
use the current connection.

# Windows Terminal (CMD - db2clp)

## Release

First, unzip the file log4db2.zip, and then:

    cd log4db2
    init.bat
    install.bat

## Development

    cd src\test\scripts
    init-dev
    cd ..\..\main\scripts
    install

# Windows PowerShell

## Release

First, unzip the file log4db2.zip, and then:

    cd log4db2
    .\init.ps1
    .\install.ps1

## Development

    cd src\test\scripts
    init-dev.ps1
    cd ..\..\main\scripts
    install.ps1

In general terms, there is the same set of scripts for each environment. Each
script performs the same task:

* init: Sets the environment for release mode.
* install: Installs the utility.
* reinstall: Desitnalls and installs the utility.
* tail_logs: shows the  more recent messages in the LOGS table.
* uninit: Cleans the environment.
* uninstall: Desintalls the utility.

