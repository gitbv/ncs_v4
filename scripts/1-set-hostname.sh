#!/bin/bash
ID=$(cat params.conf | grep server_id | awk -F "=" 'NF > 1 {print $2}')
COD=$(cat params.conf | grep center_code | awk -F "=" '{print $2}' | sed -e 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/')
cod=$(cat params.conf | grep center_code | awk -F "=" '{print $2}' | sed -e 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/')

if [ "$ID" == "0" ];
then
clear
echo "Please modify params.conf according to the center info and run this script again"
fi

if [ -f params.conf ];
then
# yum update
yum clean all
yum update -y

# touch /etc/hosts
echo "127.0.0.1 ${cod}ncs0${ID} ${cod}ncs0${ID}.tls.ad localhost localhost.localdomain localhost4 localhost4.localdomain4" > /etc/hosts
echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
rm -rf /etc/udev/rules.d/70-persistent-net.rules
rm -rf /etc/sysconfig/network-scripts/ifcfg-ens*

# touch /etc/hostname
echo "${cod}ncs0${ID}.tls.ad" > /etc/hostname
hostnamectl set-hostname --static ${cod}ncs0${ID}.tls.ad

echo Hostname:${cod}ncs0${ID}.tls.ad
echo Server is restarting, please wait and login to vSphere web console...
reboot

else
clear
echo "; Please edit the following two lines, then run set-hostname.sh" > params.conf
echo "; example: hostname canncs01, set 1 as server_id value, while canncs02, set 2" >> params.conf
echo "center_code=xxx" >> params.conf
echo "server_id=0" >> params.conf
echo "Please edit params.conf and run this script again"
fi

