# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash load the global resource file from our home directory
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# export our virtualenv python setting so it knows to use python3
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3

# create shortcuts for base dirs and make sure base directories are created
export SERVER_HOME=$HOME/server
export WEBSITE_HOME=$SERVER_HOME/website
export ARCHIVE_DIR=$SERVER_HOME/archive
export ARCHIVE_CURRENT=$ARCHIVE_DIR/current
export ARCHIVE_DATED=$ARCHIVE_DIR/dated
export VAGRANT_HOME=/vagrant
mkdir -p $VAGRANT_HOME/scripts
mkdir -p $SERVER_HOME/scripts

# set PATH so it includes user's private bin directories
PATH="$HOME/bin:$HOME/.local/bin:$PATH"
# set our path so we can run scripts from inside the vm
PATH=$PATH:$SERVER_HOME/scripts:$VAGRANT_HOME/scripts

cd $WEBSITE_HOME
# try to workon env for setting up python ignoring errors
source /usr/local/bin/virtualenvwrapper.sh >/dev/null 2>&1
workon env >/dev/null 2>&1