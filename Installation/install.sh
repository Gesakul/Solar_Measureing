#!/usr/bin/env bash

#---it is nessesary to use an raspberry-os-lite image!!---

#Path to config-file
CONFIG="/boot/config.txt"

#Update Raspberry
echo "update raspberry"
apt update
apt upgrade -y

#change password
echo "change pwd"
passwd

#install influxdb 1.8.9
echo "---influx---"
echo "add influx to repository"
wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/os-release
echo "deb https://repos.influxdata.com/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

echo "installing influxdb"
apt update && apt install -y influxdb

echo "start influxdb-service"
systemctl unmask influxdb.service
systemctl start influxdb
systemctl enable influxdb.service

#------------------------------------
#Influx Configuration
echo "setting-up influxdb"
apt-get install curl

sed -i '/ # Determines whether HTTP endpoint is enabled./!b;n;c  \ \ \ \ enabled = true' /etc/influxdb/influxdb.conf
sed -i '/ # The bind address used by the HTTP service./!b;n;c  \ \ \ \ bind-address = ":8086"' /etc/influxdb/influxdb.conf
systemctl restart influxdb
curl -XPOST 'http://localhost:8086/query' --data-urlencode 'q=CREATE DATABASE "Backup_Data"'


#------------------------------------

echo "setting up required modules"
#install python pip
apt install -y python3-pip

#install python-influx
pip3 install influxdb

#install numpy
pip3 install numpy
apt-get install libatlas-base-dev

#install yaml-load
pip3 install pyyaml

#install RPi.GPIO
pip3 install RPi.GPIO

#install pyudev
pip3 install pyudev

#install serial
pip3 install pyserial

#------------------------------------

#install on-off-switch
echo "setting up requirements for on- off- switch"

if grep -Fq "dtoverlay=gpio-shutdown,gpio_pin=3, active_low=1,gpio_pull=up" $CONFIG
then 
	echo "line already exists"
else 
	echo "added line to config-file"
	echo "#Configuration for on- off- switch" >> $CONFIG
	echo "dtoverlay=gpio-shutdown,gpio_pin=3, active_low=1,gpio_pull=up" >> $CONFIG
	echo " " >> $CONFIG
fi

#------------------------------------

#installing spi-bib
echo "installing and setting up spi-requirements"

apt-get install -y python-dev
wget https://github.com/doceme/py-spidev/archive/master.zip 
unzip master.zip
cd py-spidev-master
python setup.py install

if grep -Fq "dtparam=spi=on" $CONFIG
then
        echo "spi-bus enabled set"
        sed -i "s/#dtparam=spi=on/dtparam=spi=on/" $CONFIG
else
        echo " " >> $CONFIG
        echo "spi-bus enabled create"
        echo "#Enable spi" >> $CONFIG
        echo "dtparam=spi=on" >> $CONFIG
        echo " " >> $CONFIG
fi

#------------------------------------

#installing grafana
echo "---grafana---"
echo "add grafana to repoitory"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

echo "installing grafana"
apt update && apt install -y grafana

echo "initialize grafana"
cp influx_datasource.yaml /etc/grafana/provisioning/datasources

echo "enable & start grafana-server"
systemctl unmask grafana-server.service
systemctl start grafana-server
systemctl enable grafana-server.service



#-------------------------------------

#installing LTE-HAT
echo "----install SIM7600X 4G HAT----"
if grep -Fq "enable_uart" $CONFIG
then
        echo "enable_uart exists and set to 1 "
        sed -i "s/enable_uart=0/enable_uart=1/" $CONFIG
else
        echo " " >> $CONFIG
        echo "enable_uart create"
        echo "#Enable uart" >> $CONFIG
        echo "enable_uart=1" >> $CONFIG
        echo " " >> $CONFIG
fi

apt-get install -y minicom


#--------------------------------------

echo "WARNING: Rebooting raspi..."
reboot






