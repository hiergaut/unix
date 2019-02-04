#! /bin/bash -e

#on user pi
sudo apt-get update
sudo apt-get upgrade -y
sudo rpi-update

sudo systemctl disable bluetooth.service

sudo timedatctl set-timezone Europe/Paris
echo "country=FR" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf

echo -n "hostname : "
read hostname
echo "$hostname" | sudo tee /etc/hostname
sudo sed -i "s/raspberrypi/$hostname/" /etc/hosts

sudo passwd
