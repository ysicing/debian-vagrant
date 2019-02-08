#!/bin/bash

set -xe

date > /etc/vagrant_box_build_time

cat >> /etc/ssh/sshd_config <<EOF
UseDNS no
PasswordAuthentication yes
PermitRootLogin yes
EOF

echo 'Welcome to Vagrant-built virtual machine. -.-' > /var/run/motd

echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
echo "pre-up sleep 2" >> /etc/network/interfaces

apt-get update
apt-get -qy dist-upgrade
apt-get install -t  -y
update-grub
