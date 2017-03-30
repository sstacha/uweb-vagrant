#!/usr/bin/env bash
# this is intended to be run as the ubuntu user so they own stuff and have an env

# these variables should be set already
#export SERVER_HOME=~/server
#export WEBSITE_HOME=$SERVER_HOME/website
#export VAGRANT_HOME=/vagrant

debug () {
		if [ "$_opt_verbose" = "true" ] ; then
        	# log all messages
        	echo $1;
        fi
}

# now the virtualenv stuff can write to the python directories as it needs to
echo "logged in as: $(whoami)"
echo "updating the vagrant uweb docroot project from local server copy"
echo ""

# prompt and make sure they really want to do this
echo "The purpose of this script is for me to refresh the vagrant version in files/ to match my current version in "
echo "server deleting any extra stuff. This will then be checked in for new installs."
echo "Under normal cercumstances you should not do this."
echo "     If in doubt say no..."
echo ""
echo 'Are you sure you want to refresh the vagrant version of the docroot application with your own for new installs? [y/N]'
read _user_answer
debug "user answer: [$_user_answer]"
echo ""
if [[ "$_user_answer" != "y" && "$_user_answer" != "Y" ]]; then
    echo "skipping refresh..."
else
    # lets keep this simple; delete any existing directory then copy the docroot folder and delete the files we don't want
    # NOTE: doing this 2x so we can separate the example stuff?
    if [[ -d "$VAGRANT_HOME/files/docroot" ]]; then
        rm -rf $VAGRANT_HOME/files/docroot
    fi
    cp -Rp $WEBSITE_HOME/docroot $VAGRANT_HOME/files/docroot
    # remove all the python temporary files
    find $VAGRANT_HOME/files/docroot | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rf
    # remove the settings_common.py as we never want to mess with it (it has their secret key and such)
    rm -f $VAGRANT_HOME/files/docroot/settings_common.py
    # remove the urls.py since we don't want to overwrite anything the developer has set up (we don't use it)
    rm -f $VAGRANT_HOME/files/docroot/urls.py
fi
