#!/bin/bash
#yum -y install epel-release yum-plugin-priorities
curl -o /etc/yum.repos.d/powerdns-rec-42.repo https://repo.powerdns.com/repo-files/centos-rec-42.repo
yum -y update
yum -y install pdns-recursor dhcp pbis-open

cat > /etc/pdns-recursor/forward.conf <<eof
+green-pass.eu=10.91.82.13,10.91.98.17,10.91.50.13,10.91.120.13,10.91.226.10,10.91.230.10,10.91.242.10,10.91.246.10
+tlscontact.com=10.91.82.13,10.91.98.17,10.91.50.13,10.91.120.13,10.91.226.10,10.91.230.10,10.91.242.10,10.91.246.10
+tlscontact.cn=10.91.82.13,10.91.98.17,10.91.50.13,10.91.230.10,10.91.82.70,10.91.98.40
+tls.ad=10.91.82.13,10.91.98.17,10.91.50.13,10.91.120.13
+tls.vpn=10.91.82.13,10.91.98.17,10.91.50.13,10.91.120.13
+tls.vpnc=10.91.82.13,10.91.98.17,10.91.50.13,10.91.120.13
+tls.vpnw=10.91.82.13,10.91.98.17,10.91.50.13,10.91.120.13
+tls.ext=10.91.82.13,10.91.98.17,10.91.50.13,10.91.120.13
+172.in-addr.arpa=10.91.82.13,10.91.98.17,10.91.50.13,10.91.120.13
+10.in-addr.arpa=10.91.82.13,10.91.98.17,10.91.50.13,10.91.120.13

eof

mv /etc/pdns-recursor/recursor.conf /etc/pdns-recursor/recursor.conf.$(date '+%Y%m%d%H%M')

echo "allow-from=127.0.0.0/8, 10.0.0.0/8, 192.168.0.0/16" > /etc/pdns-recursor/recursor.conf
echo "#api-key=pdns-recursor" >> /etc/pdns-recursor/recursor.conf
echo "dnssec=process-no-validate" >> /etc/pdns-recursor/recursor.conf
echo "export-etc-hosts=yes" >> /etc/pdns-recursor/recursor.conf
echo "forward-zones-file=/etc/pdns-recursor/forward.conf" >> /etc/pdns-recursor/recursor.conf
echo "forward-zones-recurse=.=10.91.82.13;10.91.98.17;10.91.120.13" >> /etc/pdns-recursor/recursor.conf
echo "local-address=0.0.0.0" >> /etc/pdns-recursor/recursor.conf
echo "#lua-dns-script=/data/web-filter.lua" >> /etc/pdns-recursor/recursor.conf
echo "setgid=pdns-recursor" >> /etc/pdns-recursor/recursor.conf
echo "setuid=pdns-recursor" >> /etc/pdns-recursor/recursor.conf
echo "snmp-agent=no" >> /etc/pdns-recursor/recursor.conf
echo "trace=no" >> /etc/pdns-recursor/recursor.conf
echo "#webserver=yes" >> /etc/pdns-recursor/recursor.conf
echo "#webserver-readonly=no" >> /etc/pdns-recursor/recursor.conf
echo "#webserver-address=0.0.0.0" >> /etc/pdns-recursor/recursor.conf
echo "#webserver-allow-from=127.0.0.1,::/0" >> /etc/pdns-recursor/recursor.conf
echo "#webserver-password=pdns-recursor" >> /etc/pdns-recursor/recursor.conf
echo "#webserver-port=8082" >> /etc/pdns-recursor/recursor.conf

## curl -v -H 'X-API-Key: pdns-recursor' -u 'root:pdns-recursor' http://127.0.0.1:8082

mv /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.$(date '+%Y%m%d%H%M')

echo "authoritative;" > /etc/dhcp/dhcpd.conf
echo "ddns-update-style none;" >> /etc/dhcp/dhcpd.conf
echo "ignore client-updates;" >> /etc/dhcp/dhcpd.conf
echo "default-lease-time 43200;" >> /etc/dhcp/dhcpd.conf
echo "max-lease-time 86400;" >> /etc/dhcp/dhcpd.conf
echo "always-broadcast on;" >> /etc/dhcp/dhcpd.conf
echo "option time-servers 10.91.82.13,10.91.50.13;" >> /etc/dhcp/dhcpd.conf
echo "allow unknown-clients;" >> /etc/dhcp/dhcpd.conf
echo "#include \"/etc/dhcp/failover.conf\";" >> /etc/dhcp/dhcpd.conf

cp /usr/lib/systemd/system/dhcpd.service /etc/systemd/system/


if [ -f vlans.txt ];
then
SID=$(cat params.conf | grep server_id | awk -F "=" 'NF > 1 {print $2}')
cat vlans.txt | while read line
do
echo $line
ID=$(echo $line | awk -F " " {'print $1'})
NA=$(echo $line | awk -F " " {'print $2'})
NET=$(echo $line | awk -F " " {'print $3'})
IP=$(echo $line | awk -F " " {'print $4'})
GW=$(echo $NET | awk -F "." {'print $1"."$2"."$3"."$4+1'})
NM=$(echo $line | awk -F " " {'print $5'})
RG1=$(echo $IP | awk -F "." {'print $1"."$2"."$3"."$4-50'})
RG2=$(echo $IP | awk -F "." {'print $1"."$2"."$3"."$4-5'})

if [ "$SID" == "1" ];
then
NS=$(echo $IP | awk -F "." {'print $1"."$2"."$3"."$4-1'})
BC=$(echo $IP | awk -F "." {'print $1"."$2"."$3"."$4+1'})
RG1=$(echo $IP | awk -F "." {'print $1"."$2"."$3"."$4-54'})
RG2=$(echo $IP | awk -F "." {'print $1"."$2"."$3"."$4-4'})
elif [ "$SID" == "2" ];
then
NS=$(echo $IP | awk -F "." {'print $1"."$2"."$3"."$4+1'})
BC=$(echo $IP | awk -F "." {'print $1"."$2"."$3"."$4+2'})
RG1=$(echo $IP | awk -F "." {'print $1"."$2"."$3"."$4-53'})
RG2=$(echo $IP | awk -F "." {'print $1"."$2"."$3"."$4-3'})
else
clear
echo "Please modify params.conf according to the center info and run this script again"
fi

echo "include \"/etc/dhcp/$ID-$NA-dhcp.conf\";" >> /etc/dhcp/dhcpd.conf

sed -i 's/^ExecStart.*/& 'ens192.$ID'/g' /etc/systemd/system/dhcpd.service

echo "### $NA vlan" > /etc/dhcp/$ID-$NA-dhcp.conf
echo "subnet $NET netmask $NM {" >> /etc/dhcp/$ID-$NA-dhcp.conf
echo "option subnet-mask $NM;" >> /etc/dhcp/$ID-$NA-dhcp.conf
echo "option domain-name \"tls.ad\";" >> /etc/dhcp/$ID-$NA-dhcp.conf
echo "option domain-name-servers $IP,$NS;" >> /etc/dhcp/$ID-$NA-dhcp.conf
echo "option routers $GW;" >> /etc/dhcp/$ID-$NA-dhcp.conf
echo "option broadcast-address $BC;" >> /etc/dhcp/$ID-$NA-dhcp.conf
echo "#pool { failover peer \"dhcp\";" >> /etc/dhcp/$ID-$NA-dhcp.conf
echo "range "$RG1" "$RG2";" >> /etc/dhcp/$ID-$NA-dhcp.conf
echo "##}" >> /etc/dhcp/$ID-$NA-dhcp.conf
echo "}" >> /etc/dhcp/$ID-$NA-dhcp.conf
echo "## Fixed Address " >> /etc/dhcp/$ID-$NA-dhcp.conf
echo "# host tlsxxx-l0001 { hardware ethernet a1:b2:c3:d4:e5:f6; fixed-address 10.11.12.13; }" >> /etc/dhcp/$ID-$NA-dhcp.conf
echo "## Deny MAC to obtain IP" >> /etc/dhcp/$ID-$NA-dhcp.conf
echo "# host name{hardware ethernet $MAC;deny booting;}" >> /etc/dhcp/$ID-$NA-dhcp.conf


done

## disabled dhcp on vlan interfaces
#sed -i '/.*20-NETW-dhcp.conf/s/^/#&/g' /etc/dhcp/dhcpd.conf
#sed -i '/.*28-EXT-dhcp.conf/s/^/#&/g' /etc/dhcp/dhcpd.conf
#sed -i '/.*999-WIFI-dhcp.conf/s/^/#&/g' /etc/dhcp/dhcpd.conf
sed -i 's/ens192.20 //g' /etc/systemd/system/dhcpd.service
sed -i 's/ens192.28 //g' /etc/systemd/system/dhcpd.service
sed -i 's/ens192.999//g' /etc/systemd/system/dhcpd.service

systemctl --system daemon-reload
systemctl enable dhcpd
systemctl restart dhcpd
systemctl status dhcpd -l

systemctl enable pdns-recursor
systemctl restart pdns-recursor
systemctl status pdns-recursor -l

else
echo "Please be sure you had vlans.txt file and the given information is correct, then start over again"
fi


if [ -f /opt/pbis/bin/domainjoin-cli ];
then
echo -e "\n\033[5;4;47;34m  Type your a.account to join to tls.ad  \033[0m\n"
/opt/pbis/bin/domainjoin-cli join tls.ad
/opt/pbis/bin/config UserDomainPrefix TLS
/opt/pbis/bin/config AssumeDefaultDomain true
/opt/pbis/bin/config LoginShellTemplate /bin/bash
/opt/pbis/bin/config HomeDirTemplate %H/%U
/opt/pbis/bin/config RequireMembershipOf "TLS\\gu.itops.adm"
else
echo "Please install pbis-open and join to tls.ad again."
fi
