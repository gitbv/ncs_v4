#!/bin/bash
code=$(cat params.conf | grep center_code | awk -F "=" '{print $2}' |sed -e 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/')
#HN=$(hostname -s |awk -F "ncs" '{print $1}')
HN=$code-ncs1
echo -e "\033[46;30m   We will only restore dhcp config files from OLD server $HN \033[0m\n"
echo -e "\033[46;30m   If the files of $HN is NOT your expected, edit the HN variable to the hostname in this script and run agin\033[0m\n"
sleep 10
if [ $(curl -s --head https://dz1d936giuu2a.cloudfront.net/$HN/dhcpd.conf | head -n 1 | grep "200 OK" | wc -l) -eq 1 ]
then
echo -e "\n\033[5;4;47;34mDownloading the config files of #HN from S3 bucket to /data/dhcp folder \033[0m\n"

if [ -f dhcp.txt ];
then
cat dhcp.txt | while read line
do
echo -e "\n\033[43;34m  $line  \033[0m\n"
ID=$(echo $line | awk -F " " {'print $1'})
NA=$(echo $line | awk -F " " {'print $2'})
wget -c -P /data/dhcp https://dz1d936giuu2a.cloudfront.net/$HN/$ID-$NA-dhcp.conf && \
if [ $(grep "^host" /etc/dhcp/*$NA-dhcp.conf |wc -l) -ge 1 ];
then
echo -e "\n\033[4;31m   SKIP: Below hosts have been set fixed-address in $(ls /etc/dhcp |grep $NA-dhcp.conf), TO Avoid overwriting the records, will NOT restore the hosts !!! \033[0m\n"
echo "$(grep "^host" /etc/dhcp/*$NA-dhcp.conf)"
echo -e "\n\033[5;4;47;31m   You can restore the host entries MANUALLY from /data/dhcp/ !!! \033[0m\n"
sleep 3
else
cat /data/dhcp/$ID-$NA-dhcp.conf |grep ^host >> /etc/dhcp/*$NA-dhcp.conf
echo -e "\n\033[5;4;47;34m   The fixed-address hosts have been recovered to $(ls /etc/dhcp |grep $NA-dhcp.conf)\033[0m\n"
fi
done

# restart services
systemctl restart dhcpd
systemctl status dhcpd -l
fi

else
clear
echo "The files of $HN you're downloading is not existing, please check the $HN if list in https://dz1d936giuu2a.cloudfront.net/index.html"
fi
