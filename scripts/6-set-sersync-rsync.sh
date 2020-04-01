#!/bin/bash
SID=$(cat params.conf | grep server_id | awk -F "=" 'NF > 1 {print $2}')

serSync () {
### download and install sersync
cd /tmp
wget -c https://github.com/wsgzao/sersync/raw/master/sersync2.5.4_64bit_binary_stable_final.tar.gz
tar -xzvf  sersync2.5.4_64bit_binary_stable_final.tar.gz
mkdir -p /usr/local/sersync
mv GNU-Linux-x86/* /usr/local/sersync
rmdir GNU-Linux-x86
cd /usr/local/sersync
cp confxml.xml confxml.xml.$(date +%F)

sed -i 's:watch=".*":watch="/etc/dhcp":g' confxml.xml
sed -i 's:remote ip=".*" name=".*":remote ip="'$IP'" name="dhcp":g' confxml.xml
sed -i 's:params=".*":params="-artuzv --delete --exclude='dhclient.d' --exclude='*.conf.*' --exclude='dhclient-exit-hooks.d' --exclude='failover.conf' --exclude='dhcpd.leases*' --exclude='dhcpd6.conf'":g' confxml.xml

# add environment variables
if  [ `grep -c -w "sersync" /etc/profile` == 0 ];
then
echo "PATH=$PATH:/usr/local/sersync/" >> /etc/profile
source /etc/profile
fi
# run at system startup
if  [ `grep -c -w "sersync" /etc/rc.local` == 0 ];
then
echo "/usr/local/sersync/sersync2 -r -d -o /usr/local/sersync/confxml.xml" >> /etc/rc.local
chmod +x /etc/rc.d/rc.local
fi
pkill sersync2
/usr/local/sersync/sersync2 -d -r -o /usr/local/sersync/confxml.xml &

}

rSync () {

cp /etc/rsyncd.conf /etc/rsyncd.conf.$(date +%F)
echo "uid = root" > /etc/rsyncd.conf
echo "gid = root" >> /etc/rsyncd.conf
echo "use chroot = no" >> /etc/rsyncd.conf
echo "max connections = 2" >> /etc/rsyncd.conf
echo "timeout = 300" >> /etc/rsyncd.conf
echo "pid file = /var/run/rsyncd.pid" >> /etc/rsyncd.conf
echo "lock file = /var/run/rsync.lock" >> /etc/rsyncd.conf
echo "log file = /var/log/rsyncd.log" >> /etc/rsyncd.conf
echo "ignore errors" >> /etc/rsyncd.conf
echo "read only = false" >> /etc/rsyncd.conf
echo "list = false" >> /etc/rsyncd.conf
echo "hosts allow = $IP" >> /etc/rsyncd.conf
echo "hosts deny = *" >> /etc/rsyncd.conf
#rsync without authorization #
#auth users = backup
#secrets file = /etc/rsyncd.pass
#[module name]#
echo "[dhcp]" >> /etc/rsyncd.conf
echo "path = /etc/dhcp" >> /etc/rsyncd.conf
echo "comment = \"DHCP config synchronizing\"" >> /etc/rsyncd.conf
# run at system startup
if  [ `grep -c -w "rsync" /etc/rc.local` == 0 ];
then
echo "/usr/bin/rsync --daemon /etc/rsyncd.conf" >>/etc/rc.local
chmod +x /etc/rc.d/rc.local
fi
pkill rsync
rsync --daemon /etc/rsyncd.conf
}

if [ "$SID" == "1" ];
then
echo -e "\n\033[5;4;47;34m   This is $(hostname -s) server 1, setup as sersync!!  \033[0m\n"
IP=$(ifconfig ens192.20 | grep -w "inet" | awk '{ print $2}'| awk -F. '{print $1"."$2"."$3"."$4-1}')
serSync
sleep 5
echo -e "\n\033[5;4;47;34m   >>> sersync configuration done!!  \033[0m\n"
elif [ "$SID" == "2" ];
then
echo -e "\n\033[5;4;47;34m   This is $(hostname -s) server 2, setup as rsync!!  \033[0m\n"
IP=$(ifconfig ens192.20 | grep -w "inet" | awk '{ print $2}'| awk -F. '{print $1"."$2"."$3"."$4+1}')
rSync
sleep 5
echo -e "\n\033[5;4;47;34m   >>> rsync configuration done!!  \033[0m\n"
else
clear
echo "Please modify params.conf according to the center info and run this script again"
fi
