#!/usr/bin/env bash

# common functions for routing and error handling
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

export UBUNTU_HOME=/home/ubuntu
export SERVER_HOME=$UBUNTU_HOME/server
export WEBSITE_HOME=$SERVER_HOME/website
export VAGRANT_HOME=/vagrant
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3

cat $VAGRANT_HOME/files/.profile > /home/ubuntu/.profile
# . /home/ubuntu/.profile
# NOTE: we can't depend on variables set here since we run as root; HOME and other dirs would be incorrect

# set up our required users and groups we need
getent group _developer || groupadd _developer
getent group www-data || groupadd www-data
# id -u ubuntu &>/dev/null || useradd -d /vagrant/ubuntu -g www-data -m -G sudo ubuntu
# NOTE: instead of changing ownership of the www-data files I am instead adding ubuntu
# 	group to www-data user since vagrant takes care of making sure those are always set
usermod -a -G www-data ubuntu
usermod -a -G _developer ubuntu

# NOTE: had problems with permissions not being set right.  
# making sure these are created as ubuntu not root on provisioning

# set up server home
mkdir -p $SERVER_HOME
chown ubuntu:www-data $SERVER_HOME
chmod 775 $SERVER_HOME
# set up local scripts dir
mkdir -p $SERVER_HOME/scripts
chown ubuntu:ubuntu $SERVER_HOME/scripts
chmod 775 $SERVER_HOME/scripts
# set up server scripts dir that user shouldn't change
mkdir -p $VAGRANT_HOME/scripts
chown ubuntu:ubuntu $VAGRANT_HOME/scripts
chmod 775 $VAGRANT_HOME/scripts
# set up django website home project directories
#   including cache static and images used for file storage that nginx points to
mkdir -p $WEBSITE_HOME
chown ubuntu:www-data $WEBSITE_HOME
chmod 775 $WEBSITE_HOME
mkdir -p $WEBSITE_HOME/cache
chown ubuntu:www-data $WEBSITE_HOME/cache
chmod 775 $WEBSITE_HOME/cache
mkdir -p $WEBSITE_HOME/static
chown ubuntu:ubuntu $WEBSITE_HOME/static
chmod 775 $WEBSITE_HOME/static
mkdir -p $WEBSITE_HOME/images
chown ubuntu:www-data $WEBSITE_HOME/images
chmod 775 $WEBSITE_HOME/images
mkdir -p $WEBSITE_HOME/docroot
# set up the main djano application direcotry (docroot)
chown ubuntu:www-data $WEBSITE_HOME/docroot
chmod 775 $WEBSITE_HOME/docroot
# set up the config directory to hold the image_optium config file
mkdir -p $SERVER_HOME/config
chown ubuntu:ubuntu $SERVER_HOME/config
# set up the archive directories for the archive script
mkdir -p $SERVER_HOME/archive
chown ubuntu:ubuntu $SERVER_HOME/archive
chmod 775 $SERVER_HOME/archive
mkdir -p $SERVER_HOME/archive/dated
chown ubuntu:ubuntu $SERVER_HOME/archive/dated
chmod 775 $SERVER_HOME/archive/dated
mkdir -p $SERVER_HOME/archive/current
chown ubuntu:ubuntu $SERVER_HOME/archive/current
chmod 775 $SERVER_HOME/archive/current
mkdir -p $UBUNTU_HOME/.ssh/
# consider locking this down to 700 after we get it working (really no one but ubuntu should be able to see the keys)
chown ubuntu:ubuntu $UBUNTU_HOME/.ssh/
chmod 755 $UBUNTU_HOME/.ssh/

# make sure we are dealing with the latest stuff
try apt-get update
try apt-get -y upgrade

# install all "basic applications and dev dependencies" we need
try apt-get install -y build-essential git nginx lynx imagemagick nodejs
# try to install nodejs from source so we can use the version we want in our vm (supported)
# NOTE: this was required when this was a node project; now it is django we still need for images but we can use an older version
#   that is maintained by the package manager
# ----- how to build from source -----
#X_ARCH="$(getconf LONG_BIT)"
#echo "building for arch " + $X_ARCH
#wget https://nodejs.org/dist/v7.5.0/node-v7.5.0-linux-x$X_ARCH.tar.xz
#tar -C /usr/local --strip-components 1 -xJf node-v7.5.0-linux-x$X_ARCH.tar.xz
#rm node-v7.5.0-linux-x$X_ARCH.tar.xz
# ----- how to build from source -----

# install all python stuff for django (should come installed with latest 16.04)
try apt-get install -y libffi-dev python3-dev
echo "$(python3 -V)"
try apt-get install -y python3-pip python3-venv
# decided we don't want to do this; there may be a case where someone needs a python2 and 3 env at the same time
# ln -s /usr/bin/pip3 /usr/bin/pip
pip3 install --upgrade pip
echo "$(pip3 -V)"

# install all security stuff
try apt-get install -y libsasl2-dev libldap2-dev libssl-dev

# install all image stuff for the image processing
try apt-get install -y xz-utils inotify-tools
try apt-get install -y libjpeg-progs
try apt-get install -y jhead optipng pngcrush jpegoptim advancecomp gifsicle pngquant
try apt-get install -y ruby

# copy over the nginx file
cp -f $VAGRANT_HOME/files/default /etc/nginx/sites-available/default
cp $VAGRANT_HOME/files/image_optim.yml $SERVER_HOME/config/image_optim.yml
chown ubuntu:ubuntu $SERVER_HOME/config/image_optim.yml

# get the latest npm since current one fails on optional stuff for pm2
npm install -g npm@latest
npm install -g svgo

# install the gem for image_optim image optimizer our cms will use
gem install image_optim

# found that ubuntu user and _developer group should own everything under /usr/local/ for python an node stuff after they are installed
chown -R ubuntu:_developer /usr/local/

# have root setup our direcotries for uwsgi and place the config file if we  do not have a website/manage.py
if [ ! -f $WEBSITE_HOME/"manage.py" ]; then
    # test uwsgi by command line...
    # uwsgi --http :8080 --chdir /home/ubuntu/server/website --home /home/ubuntu/.virtualenvs/env -w docroot.wsgi
    # debug log: journalctl -xe
    mkdir -p /etc/uwsgi/sites
    mkdir -p /run/uwsgi
    chown ubuntu:www-data /run/uwsgi
    chmod g+w /run/uwsgi
    echo "should have created and modified permissions for /run/uwsgi"
    echo "$(ls -al /run/)"
    # copy the uwsgi config in place
    cp -f $VAGRANT_HOME/files/uwsgi_uweb.ini /etc/uwsgi/sites/uwsgi_uweb.ini
    echo "**** finished copying everything for uwsgi; about to run script as ubuntu for installs"
fi

# attempt to call our script as ubuntu user and set up the virtualenv with stuff if needed
su ubuntu $VAGRANT_HOME/install_uweb.sh
echo "**** finished run script as ubuntu for installs"

# install grunt globally for our image handling and other internal processing 
#npm install -g grunt-cli

# change to our project directory containing the package.json file and make sure all dependencies (grunt among others) are installed locally to project
#cd $VAGRANT_HOME/uweb
#npm install --no-bin-links
#cd $WEBSITE_HOME

# copy over the service files to the systemd directory for starting our uweb application and any other services
# uweb.service: uweb django application at boot
# uwsgi.service: nginx -> django process at boot
echo "**** setting up and turning on services"
cp -f $VAGRANT_HOME/files/uweb.service /etc/systemd/system/uweb.service
cp -f $VAGRANT_HOME/files/uwsgi.service /etc/systemd/system/uwsgi.service
# echo "**** setting up udev trigger for services"
# cp -f $VAGRANT_HOME/files/50-vagrant-mount-rules.sh /etc/udev/rules.d/50-vagrant-mount.rules

# start our cms service and print the status to console
systemctl enable uweb
#systemctl start uweb
#systemctl status uweb

# start our uwsgi service and print the status to console
systemctl enable uwsgi
systemctl start uwsgi
systemctl status uwsgi

# re-start our uwsgi service and print the status to console to pick up the new config and uwsgi integration
systemctl stop nginx
systemctl start nginx
systemctl status nginx
