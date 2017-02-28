# common functions for routing and error handling
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

cat /vagrant/vm_files/.profile > /home/ubuntu/.profile
. /home/ubuntu/.profile

getent group _developer || groupadd _developer
getent group www-data || groupadd www-data

# NOTE: had problems with permissions not being set right.  
# making sure these are created as ubuntu not root on provisioning
mkdir -p /home/ubuntu/vm_scripts
chown ubuntu:ubuntu /home/ubuntu/vm_scripts
chmod 775 /home/ubuntu/vm_scripts
#mkdir -p /home/ubuntu/uploads
export WEBSITE_BASE=/home/ubuntu/website
mkdir -p $WEBSITE_BASE
chown ubuntu:ubuntu $WEBSITE_BASE
chmod 775 $WEBSITE_BASE
mkdir -p $WEBSITE_BASE/cache
chown ubuntu:ubuntu $WEBSITE_BASE/cache
chmod 775 $WEBSITE_BASE/cache
#mkdir -p $WEBSITE_BASE/uploads
#chown ubuntu:ubuntu $WEBSITE_BASE/uploads
#chmod 775 $WEBSITE_BASE/uploads
mkdir -p $WEBSITE_BASE/images
chown ubuntu:ubuntu $WEBSITE_BASE/images
chmod 775 $WEBSITE_BASE/images
mkdir -p $WEBSITE_BASE/docroot
chown ubuntu:ubuntu $WEBSITE_BASE/docroot
chmod 775 $WEBSITE_BASE/docroot
mkdir -p /home/ubuntu/config
chown ubuntu:ubuntu /home/ubuntu/config

try apt-get update
try apt-get install build-essential git nginx lynx imagemagick -y
# try to install nodejs from source so we can use the version we want in our vm (supported)
X_ARCH="$(getconf LONG_BIT)"
echo "building for arch " + $X_ARCH
wget https://nodejs.org/dist/v7.5.0/node-v7.5.0-linux-x$X_ARCH.tar.xz
tar -C /usr/local --strip-components 1 -xJf node-v7.5.0-linux-x$X_ARCH.tar.xz

try apt-get install xz-utils inotify-tools -y
try apt-get install libjpeg-progs -y
try apt-get install -y jhead optipng pngcrush jpegoptim advancecomp gifsicle pngquant
try apt-get install -y ruby

# id -u ubuntu &>/dev/null || useradd -d /vagrant/ubuntu -g www-data -m -G sudo ubuntu
# NOTE: instead of changing ownership of the www-data files I am instead adding ubuntu
# 	group to www-data user since vagrant takes care of making sure those are always set
usermod -a -G www-data ubuntu
usermod -a -G _developer ubuntu

# copy over the nginx file
cp -f /vagrant/vm_files/default /etc/nginx/sites-available/default
cp /vagrant/vm_files/image_optim.yml /home/ubuntu/config/image_optim.yml
chown ubuntu:ubuntu /home/ubuntu/config/image_optim.yml

# get the latest npm since current one fails on optional stuff for pm2
npm install -g npm@latest
npm install -g svgo

# install the gem for image_optim image optimizer our cms will use
gem install image_optim

# install grunt globally for our image handling and other internal processing 
#npm install -g grunt-cli

# change to our project directory containing the package.json file and make sure all dependencies (grunt among others) are installed locally to project
#cd $VAGRANT_BASE/uweb
#npm install --no-bin-links
#cd $WEBSITE_BASE

# install our dependencies to node modules if they exist
# copy over the service file to the systemd directory for starting our uweb application
cp -f /vagrant/vm_files/uweb.service /etc/systemd/system/uweb.service
cp -f /vagrant/vm_files/uweb_images.service /etc/systemd/system/uweb_images.service

# start our cms service and print the status to console
systemctl enable uweb
systemctl start uweb
systemctl status uweb

# start our grunt images watch service and print the status to console
#systemctl enable uweb_images
#systemctl start uweb_images
#systemctl status uweb_images

