# ip routes
ip route add table NETW default nexthop via 10.64.0.1 dev ens192.20
ip route add table LAN default nexthop via 10.64.2.1 dev ens192.21
ip route add table CAM default nexthop via 10.64.4.1 dev ens192.22
ip route add table FING default nexthop via 10.64.6.1 dev ens192.23
ip route add table SELF default nexthop via 10.64.8.1 dev ens192.24
ip route add table MNGT default nexthop via 10.64.10.1 dev ens192.25
ip route add table CC default nexthop via 10.64.12.1 dev ens192.26
ip route add table SRV default nexthop via 10.64.14.1 dev ens192.27
ip route add table EXT default nexthop via 10.64.16.1 dev ens192.28
ip route add table BIOFR default nexthop via 10.64.26.1 dev ens192.202
ip route add table BIOCH default nexthop via 10.64.28.1 dev ens192.203
ip route add table BIOHU default nexthop via 10.64.30.1 dev ens192.204
ip route add table IT default nexthop via 10.64.58.1 dev ens192.500
ip route add table WIFI default nexthop via 10.64.62.1 dev ens192.999
