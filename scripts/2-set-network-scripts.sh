#!/bin/bash
echo "DEVICE=ens192" > /etc/sysconfig/network-scripts/ifcfg-ens192
echo "BOOTPROTO=static" >> /etc/sysconfig/network-scripts/ifcfg-ens192
echo "ONBOOT=no" >> /etc/sysconfig/network-scripts/ifcfg-ens192
echo "TYPE=Ethernet" >> /etc/sysconfig/network-scripts/ifcfg-ens192
echo "IPADDR=0.0.0.0" >> /etc/sysconfig/network-scripts/ifcfg-ens192
echo "NETMASK=255.255.255.0" >> /etc/sysconfig/network-scripts/ifcfg-ens192
# touch /etc/resolv.conf
echo "search tls.ad" > /etc/resolv.conf
echo "nameserver 127.0.0.1" >> /etc/resolv.conf
echo "nameserver 10.91.82.13" >> /etc/resolv.conf
# touch /etc/sysconfig/network
echo "# Created by anaconda" > /etc/sysconfig/network
echo "PEERDNS=no" >> /etc/sysconfig/network
echo "NETWORKING=yes" >> /etc/sysconfig/network
echo "NOZEROCONF=yes" >> /etc/sysconfig/network
echo "GATEWAYDEV=ens192.20" >> /etc/sysconfig/network

if [ -f vlans.txt ];
then

echo "# ip routes" > routes.sh
chmod +x routes.sh

echo "#" > /etc/iproute2/rt_tables
echo "# reserved values" >> /etc/iproute2/rt_tables
echo "#" >> /etc/iproute2/rt_tables
echo "255     local" >> /etc/iproute2/rt_tables
echo "254     main" >> /etc/iproute2/rt_tables
echo "253     default" >> /etc/iproute2/rt_tables
echo "0 unspec" >> /etc/iproute2/rt_tables
echo "#" >> /etc/iproute2/rt_tables
echo "# local" >> /etc/iproute2/rt_tables

cat vlans.txt | while read line
do
echo $line
ID=$(echo $line | awk -F " " {'print $1'})
NA=$(echo $line | awk -F " " {'print $2'})
NET=$(echo $line | awk -F " " {'print $3'})
IP=$(echo $line | awk -F " " {'print $4'})
GW=$(echo $NET | awk -F "." {'print $1"."$2"."$3"."$4+1'})
NM=$(echo $line | awk -F " " {'print $5'})

echo "$ID $NA" >> /etc/iproute2/rt_tables

echo "#$ID - $NA" > /etc/sysconfig/network-scripts/ifcfg-ens192.$ID
echo "VLAN=yes" >> /etc/sysconfig/network-scripts/ifcfg-ens192.$ID
echo "DEVICE=ens192.$ID" >> /etc/sysconfig/network-scripts/ifcfg-ens192.$ID
echo "IPV6INIT=no" >>/etc/sysconfig/network-scripts/ifcfg-ens192.$ID
echo "BOOTPROTO=none" >> /etc/sysconfig/network-scripts/ifcfg-ens192.$ID
echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-ens192.$ID
echo "NM_CONTROLLED=no" >> /etc/sysconfig/network-scripts/ifcfg-ens192.$ID
echo "TYPE=Ethernet" >> /etc/sysconfig/network-scripts/ifcfg-ens192.$ID
echo "IPADDR=$IP" >> /etc/sysconfig/network-scripts/ifcfg-ens192.$ID
echo "NETMASK=$NM" >> /etc/sysconfig/network-scripts/ifcfg-ens192.$ID
echo "GATEWAY=$GW" >> /etc/sysconfig/network-scripts/ifcfg-ens192.$ID

echo "ip route add table $NA default nexthop via $GW dev ens192.$ID" >> routes.sh

done
echo "#" >> /etc/iproute2/rt_tables
echo "#1        inr.ruhep" >> /etc/iproute2/rt_tables
else
   echo "Run the script in the same directory with vlans.txt"
fi


# add firewalld policies
echo -e "\n\033[5;4;47;34m Firewalld settings \033[0m\n"
# ssh
firewall-cmd --permanent --zone=public --add-port=13333/tcp
# dns
firewall-cmd --permanent --zone=public --add-port=53/tcp
firewall-cmd --permanent --zone=public --add-port=53/udp
# pdns-recursor webserver
firewall-cmd --permanent --zone=public --add-port=8082/tcp
# dhcp
firewall-cmd --permanent --zone=public --add-port=67/udp
firewall-cmd --permanent --zone=public --add-port=520/tcp
# ntp
firewall-cmd --permanent --zone=public --add-port=123/udp
# snmp
firewall-cmd --permanent --zone=public --add-port=199/tcp
firewall-cmd --permanent --zone=public --add-port=161/udp
# rsync
firewall-cmd --permanent --zone=public --add-port=873/tcp
# reload
firewall-cmd --reload

echo -e "\n\033[5;4;47;34mCreating sub-interfaces, please wait... \033[0m\n"
systemctl restart network

