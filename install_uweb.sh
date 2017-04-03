#!/usr/bin/env bash
# this is intended to be run as the ubuntu user so they own stuff and have an env

export UBUNTU_HOME=/home/ubuntu
export SERVER_HOME=$UBUNTU_HOME/server
export WEBSITE_HOME=$SERVER_HOME/website
export VAGRANT_HOME=/vagrant
# determines the initial python to use before the virtualenv is created
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
# determines the initial pip to use before the virtualenv is created
export VIRTUALENVWRAPPER_PIP=pip3

# now the virtualenv stuff can write to the python directories as it needs to
echo whoami
echo "installing virtualenv and setting up base django project"
echo ""

$VIRTUALENVWRAPPER_PIP install virtualenvwrapper
# create our virtual envrionment if it does not exist (for re-provisioning again)
source /usr/local/bin/virtualenvwrapper.sh
_tmpls=$(lsvirtualenv -b | grep "^env$")

echo "tmpls: $_tmpls"
_makeenv=true
if [[ "$_tmpls" != "" ]]; then
    # if we have a requirements.txt file ask if we want to re-provision our python environment
    echo "You requested to re-provision the machine. A virtual envrionment already exists."
    echo "NOTE: If you have done any pip installs from inside the virtual machine you may loose dependencies"
    echo "     If in doubt say no"
    echo ""
    echo 'Are you sure you want to delete and re-create the virtual environment from the requirments.txt file at this time? [y/N]'
    read _user_answer
    # echo "user answer: [$_user_answer]"
    echo ""
    if [[ "$_user_answer" != "y" && "$_user_answer" != "Y" ]]; then
        echo "skipping python envrionment provisioning..."
        _makeenv=false
    else
        deactivate >/dev/null 2>&1
        rmvirtualenv env
    fi
fi
if [[ "$_makeenv" == "true" ]]; then
    # provision the new environment and load the requirements.txt again if we have one
    $VIRTUALENVWRAPPER_PIP install virtualenv
    mkvirtualenv --python=$VIRTUALENVWRAPPER_PYTHON --no-site-packages env

fi

# at this point we should always have an environment so lets start it up for other installs
workon env

# install django required files or a base install
if [ -f "$WEBSITE_HOME/requirements.txt" ]; then
    echo "requirements.txt exists; installing or re-installing modules from it..."
    pip install -r $WEBSITE_HOME/requirements.txt
else
    echo "requirements.txt does not exist; installing base django modules..."
    cd $WEBSITE_HOME
    if [ -f "manage.py" ]; then
        echo "manage.py already exists: skipping project install..."
    else
        pip install --upgrade pip
        pip install django
        django-admin startproject docroot .
        python manage.py migrate
        echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin@example.com', 'admin', 'admin')" | python3 manage.py shell
        sed -i 's/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \[\"\*\"\]/' docroot/settings.py
        echo 'STATIC_ROOT = os.path.join(BASE_DIR, "static/")' >> docroot/settings.py
        pip install uwsgi

        # create an initial requirements.txt file for the host to build a virtual envrionment from
        $VAGRANT_HOME/scripts/update_env

        # rename the original settings.py file to settings_common.py
        # ours will be copied in next; which will insert the uweb application into the mix
        mv $WEBSITE_HOME/docroot/settings.py $WEBSITE_HOME/docroot/settings_common.py
        # copy all our default directories and files from the vagrant install folder to
        cp -R $VAGRANT_HOME/files/docroot/ $WEBSITE_HOME/
        # finally, ask if they want some sample data created
#        echo "There are a few sample files that can be copied into the docroot if you would like.  These can easily be"
#        echo "removed later.  See the getting started tutorial @ https://www.ubercode.io/uweb/tutorials for more info."
#        echo "NOTE:  If in doubt probably best to say yes (y)"
#        echo ""
#        echo 'Do you want to copy example files into the installed docroot? [Y/n]'
#        read _user_answer
#        # echo "user answer: [$_user_answer]"
#        echo ""
#        if [[ "$_user_answer" != "y" && "$_user_answer" != "Y" && "$_user_answer" != "" ]]; then
#            echo "copying example files..."
#            cp -R $VAGRANT_HOME/files/docroot_examples/ $WEBSITE_HOME/docroot/
#        else
#            echo "skipping example files..."
#        fi
    fi
fi