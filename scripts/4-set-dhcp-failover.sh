#!/bin/bash
SID=$(cat params.conf | grep server_id | awk -F "=" 'NF > 1 {print $2}')
IP=$(cat vlans.txt | grep NETW | awk -F " " {'print $4'})

if [ "$SID" == "1" ];
then
PIP=$(echo $IP | awk -F "." {'print $1"."$2"."$3"."$4-1'})
echo "failover peer \"dhcp\" {" > /etc/dhcp/failover.conf
echo "primary;" >> /etc/dhcp/failover.conf
echo "address $IP;" >> /etc/dhcp/failover.conf
echo "port 520;" >> /etc/dhcp/failover.conf
echo "peer address $PIP;" >> /etc/dhcp/failover.conf
echo "peer port 520;" >> /etc/dhcp/failover.conf
echo "max-response-delay 60;" >> /etc/dhcp/failover.conf
echo "max-unacked-updates 10;" >> /etc/dhcp/failover.conf
echo "load balance max seconds 3;" >> /etc/dhcp/failover.conf
echo "mclt 3600;" >> /etc/dhcp/failover.conf
echo "split 128;" >> /etc/dhcp/failover.conf
echo "}" >> /etc/dhcp/failover.conf
echo -e "\n\033[5;4;47;34m   Primary failover config created   \033[0m\n"

elif [ "$SID" == "2" ];
then
PIP=$(echo $IP | awk -F "." {'print $1"."$2"."$3"."$4+1'})
echo "failover peer \"dhcp\" {" > /etc/dhcp/failover.conf
echo "secondary;" >> /etc/dhcp/failover.conf
echo "address $IP;" >> /etc/dhcp/failover.conf
echo "port 520;" >> /etc/dhcp/failover.conf
echo "peer address $PIP;" >> /etc/dhcp/failover.conf
echo "peer port 520;" >> /etc/dhcp/failover.conf
echo "max-response-delay 60;" >> /etc/dhcp/failover.conf
echo "max-unacked-updates 10;" >> /etc/dhcp/failover.conf
echo "load balance max seconds 3;" >> /etc/dhcp/failover.conf
echo "}" >> /etc/dhcp/failover.conf
echo -e "\n\033[5;4;47;34m   Secondary failover config created   \033[0m\n"
else
clear
echo "Please modify params.conf according to the center info and run this script again"
fi
# enable failover
sed -i '/failover.conf/s/^#//' /etc/dhcp/dhcpd.conf

cat vlans.txt | while read line
do
echo $line
ID=$(echo $line | awk -F " " {'print $1'})
NA=$(echo $line | awk -F " " {'print $2'})
sed -i '/pool/s/^#//' /etc/dhcp/$ID-$NA-dhcp.conf 2>/dev/null
sed -i 's/^##}/\}/g'  /etc/dhcp/$ID-$NA-dhcp.conf 2>/dev/null
done

# restart services
systemctl restart dhcpd
systemctl status dhcpd -l

