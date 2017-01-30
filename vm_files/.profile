# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# create shortcuts for base dirs and make sure base directories are created
export WEBSITE_BASE=/home/ubuntu/website
export VAGRANT_BASE=/vagrant
mkdir -p $VAGRANT_BASE/vm_scripts
mkdir -p $HOME/vm_scripts

# set PATH so it includes user's private bin directories
PATH="$HOME/bin:$HOME/.local/bin:$PATH"
# set our path so we can run scripts from inside the vm
PATH=$PATH:$HOME/vm_scripts:$VAGRANT_BASE/vm_scripts

cd $WEBSITE_BASE
