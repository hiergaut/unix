#! /bin/bash -e


if [ -z $SSH_TTY ]; then

    sudo ip addr add 192.168.0.100/24 broadcast 192.168.0.255 dev eth0
    sudo ip route add default via 192.168.0.254
fi
