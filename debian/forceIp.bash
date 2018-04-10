#! /bin/bash -e

echo -n "your ip : "
read ip

ip addr add 192.168.0.$ip/24 broadcast 192.168.0.255 dev eth0
ip route add default via 192.168.0.254
