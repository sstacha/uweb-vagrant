# common functions for routing and error handling
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

cat /vagrant/vm_files/.profile > /home/ubuntu/.profile
. /home/ubuntu/.profile

getent group _developer || groupadd _developer

# NOTE: had problems with permissions not being set right.  
# making sure these are created as ubuntu not root on provisioning
mkdir -p /home/ubuntu/vm_scripts
export WEBSITE_BASE=/home/ubuntu/website
mkdir -p $WEBSITE_BASE
chown ubuntu:ubuntu $WEBSITE_BASE
chmod 775 $WEBSITE_BASE
mkdir -p $WEBSITE_BASE/static
chown ubuntu:ubuntu $WEBSITE_BASE/static
mkdir -p $WEBSITE_BASE/cache
chown ubuntu:ubuntu $WEBSITE_BASE/cache
mkdir -p $WEBSITE_BASE/upload
chown ubuntu:ubuntu $WEBSITE_BASE/upload
mkdir -p $WEBSITE_BASE/docroot
chown ubuntu:ubuntu $WEBSITE_BASE/docroot
chmod 775 $WEBSITE_BASE/docroot
mkdir -p $WEBSITE_BASE/code
chown ubuntu:ubuntu $WEBSITE_BASE/code

try apt-get update
try apt-get install nodejs build-essential git nginx -y

# id -u ubuntu &>/dev/null || useradd -d /vagrant/ubuntu -g www-data -m -G sudo ubuntu
# NOTE: instead of changing ownership of the www-data files I am instead adding ubuntu
# 	group to www-data user since vagrant takes care of making sure those are always set
usermod -a -G www-data ubuntu
usermod -a -G _developer ubuntu

# provisioning blank website project code from git if the directory does not exist
# NOTE: assuming ../website directory so developer can check in as thier own code.
# TODO: replace this call with your git docroot checkin
#if [ -d "../website/" ]; then
#    git clone 
#fi
