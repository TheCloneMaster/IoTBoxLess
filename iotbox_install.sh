#!/bin/bash
################################################################################
# Script for installing IoTBox on Ubuntu 20.04, 18.04 (could be used for other version too)
# Author: Yenthe Van Ginneken
# Author: Mario Arias
#-------------------------------------------------------------------------------
# This script will install IoTBox on your Ubuntu server. It can install multiple instances
# in one Ubuntu because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano iotbox-install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x iotbox-install.sh
# Execute the script to install Odoo:
# ./iotbox-install
################################################################################
 
##fixed parameters
#iotbox
OS_USER="boleteria"
OE_USER="iotbox"
OE_HOME="/$OE_USER"
OE_HOME_EXT="/$OE_USER/${OE_USER}-server"
#The default port where this IoTBox instance will run under (provided you use the command -c in the terminal)
#Set to true if you want to install it, false if you don't need it or have it already installed.
INSTALL_WKHTMLTOPDF="False"
#Set the default IoTBox port (you still have to use -c /etc/iotbox-server.conf for example to use this.)
OE_PORT="8069"
#Choose the Odoo version which you want to install. For example: 10.0, 9.0, 8.0, 7.0 or saas-6. When using 'trunk' the master version will be installed.
#IMPORTANT! This script contains extra libraries that are specifically needed for Odoo 10.0
OE_VERSION="main"
# Set this to True if you want to install Odoo 10 Enterprise!
IS_ENTERPRISE="False"
# Set this to True if you want to install Nginx!
INSTALL_NGINX="False"
# Set the superadmin password - if GENERATE_RANDOM_PASSWORD is set to "True" we will automatically generate a random password, otherwise we use this one
OE_SUPERADMIN="IoTBox"
# Set to "True" to generate a random password, "False" to use the variable in OE_SUPERADMIN
GENERATE_RANDOM_PASSWORD="True"
OE_CONFIG="${OE_USER}-server"
# Set to "True" to install certbot and have ssl enabled, "False" to use http
ENABLE_SSL="True"
# Provide Email to register ssl certificate
ADMIN_EMAIL="odoo@example.com"
##
###  WKHTMLTOPDF download links
## === Ubuntu Trusty x64 & x32 === (for other distributions please replace these two links,
## in order to have correct version of wkhtmltopdf installed, for a danger note refer to
## https://github.com/odoo/odoo/wiki/Wkhtmltopdf ):
## https://www.odoo.com/documentation/13.0/setup/install.html#debian-ubuntu

WKHTMLTOX_X64="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.$(lsb_release -c -s)_amd64.deb"
WKHTMLTOX_X32="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.$(lsb_release -c -s)_i386.deb"
#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
# universe package is for Ubuntu 18.x
sudo add-apt-repository universe
# libpng12-0 dependency for wkhtmltopdf
sudo add-apt-repository "deb http://mirrors.kernel.org/ubuntu/ $(lsb_release -c -s) main"
sudo apt-get update
sudo apt-get upgrade -y

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server ----"
sudo apt-get install postgresql -y

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $OS_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n--- Installing Python 3 + pip3 --"
sudo apt-get install git python3 python3-pip build-essential wget python3-dev python3-venv python3-wheel libxslt-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libjpeg-dev gdebi -y
# libpng12-0 

echo -e "\n---- Install python packages/requirements ----"
sudo -H pip3 install -r https://github.com/TheCloneMaster/IoTBoxLess/raw/main/requirements.txt

echo -e "\n---- Installing nodeJS NPM and rtlcss for LTR support ----"
sudo apt-get install nodejs npm -y
sudo npm install -g rtlcss
###echo -e "\n---- Install python libraries ----"
###sudo pip install gdata psycogreen ofxparse XlsxWriter xlrd 
#### This is for compatibility with Ubuntu 16.04. Will work on 14.04, 15.04 and 16.04
###sudo -H pip install suds
###sudo -H pip install pyserial
###sudo -H pip install pyusb==1.0.0b1
###sudo -H pip install qrcode
###
###echo -e "\n--- Install other required packages"
###sudo apt-get install node-clean-css -y
###sudo apt-get install node-less -y
###sudo apt-get install python-gevent -y
###
###
###echo -e "\n---- Create USB users ----"
sudo groupadd usbusers
sudo adduser boleteria usbusers
sudo usermod -a -G usbusers boleteria

echo -e "* Create udev USB access rules file"
cat <<EOF > /etc/udev/rules.d/99-usbusers.rules
SUBSYSTEM=="usb", GROUP="usbusers", MODE="0660"
SUBSYSTEMS=="usb", GROUP="usbusers", MODE="0660"
EOF

#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n---- Install wkhtml and place shortcuts on correct place for IoTBox ----"
  #pick up correct one from x64 & x32 versions:
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=$WKHTMLTOX_X64
  else
      _url=$WKHTMLTOX_X32
  fi
  sudo wget $_url
  sudo gdebi --n `basename $_url`
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
fi
	
#echo -e "\n---- Create IoTBox system user ----"
#sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'IOTBOX' --group $OE_USER
#The user should also be added to the sudo'ers group.
#sudo adduser $OE_USER sudo

echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$OE_USER
sudo chown $OS_USER:$OS_USER /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing PosBox Server ===="
sudo git clone --depth 1 --branch $OE_VERSION https://github.com/TheCloneMaster/IoTBoxLess.git $OE_HOME_EXT/

echo -e "\n---- Create custom module directory ----"
sudo su $OS_USER -c "mkdir $OE_HOME/custom"
sudo su $OS_USER -c "mkdir $OE_HOME/custom/addons"

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OS_USER:$OS_USER $OE_HOME/*

echo -e "* Create server config file"
sudo cp $OE_HOME_EXT/odoo/addons/point_of_sale/tools/posbox/configuration/odoo.conf /etc/${OE_CONFIG}.conf
sudo chown $OS_USER:$OS_USER /etc/${OE_CONFIG}.conf
sudo chmod 640 /etc/${OE_CONFIG}.conf

#echo -e "* Change server config file"
#sudo sed -i s/"db_user = .*"/"db_user = $OS_USER"/g /etc/${OE_CONFIG}.conf
#sudo sed -i s/"; admin_passwd.*"/"admin_passwd = $OE_SUPERADMIN"/g /etc/${OE_CONFIG}.conf
#sudo su root -c "echo '[options]' >> /etc/${OE_CONFIG}.conf"
sudo su root -c "echo 'logfile = $OE_HOME_EXT/$OE_CONFIG$1.log' >> /etc/${OE_CONFIG}.conf"
echo -e "* Change default xmlrpc port"
sudo su root -c "echo 'xmlrpc_port = $OE_PORT' >> /etc/${OE_CONFIG}.conf"
#sudo su root -c "echo 'addons_path=$OE_HOME_EXT/addons,$OE_HOME/custom/addons' >> /etc/${OE_CONFIG}.conf"

echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $OS_USER $OE_HOME_EXT/odoo/odoo-bin --config=/etc/${OE_CONFIG}.conf  --load=hw_drivers,hw_escpos,hw_posbox_homepage,point_of_sale,web' >> $OE_HOME_EXT/start.sh"
sudo chmod 755 $OE_HOME_EXT/start.sh

echo -e "* Install requirements.txt"
sudo -H pip3 install -r $OE_HOME_EXT/requirements.txt


#--------------------------------------------------
# Adding PosBox as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"
cat <<EOF > /iotbox/iotbox-server/$OE_CONFIG
#!/bin/sh
### BEGIN INIT INFO
# Provides: $OE_CONFIG
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: ODOO Business Applications
### END INIT INFO
PATH=/bin:/sbin:/usr/bin
DAEMON=$OE_HOME_EXT/odoo/odoo-bin
NAME=$OE_CONFIG
DESC=$OE_CONFIG
# Specify the user name (Default: posbox).
USER=$OS_USER
# Specify an alternate config file (Default: /etc/openerp-server.conf).
CONFIGFILE="/etc/${OE_CONFIG}.conf"
# pidfile
PIDFILE=/var/run/\${NAME}.pid
# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \$CONFIGFILE --load=hw_drivers,hw_escpos,hw_posbox_homepage,point_of_sale,web"
#DAEMON_OPTS="--load=hw_drivers,hw_escpos,hw_posbox_homepage,point_of_sale,web"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}
case "\${1}" in
start)
echo -n "Starting \${DESC}: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
stop)
echo -n "Stopping \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\${NAME}."
;;
restart|force-reload)
echo -n "Restarting \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 1
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
*)
N=/etc/init.d/\$NAME
echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;
esac
exit 0
EOF

echo -e "* Security Init File"
sudo mv /iotbox/iotbox-server/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG


echo -e "* Start ODOO on Startup"
sudo update-rc.d $OE_CONFIG defaults

echo -e "* Starting PosBox Service"
sudo su root -c "/etc/init.d/$OE_CONFIG start"
echo "-----------------------------------------------------------"
echo "Done! The PosBox server is up and running. Specifications:"
echo "Port: $OE_PORT"
echo "User service: $OE_USER"
echo "User PostgreSQL: $OS_USER"
echo "Code location: $OE_USER"
echo "Addons folder: $OE_USER/$OE_CONFIG/addons/"
echo "Start PosBox service: sudo service $OE_CONFIG start"
echo "Stop PosBox service: sudo service $OE_CONFIG stop"
echo "Restart PosBox service: sudo service $OE_CONFIG restart"
echo "-----------------------------------------------------------"
