#!/bin/bash

set -xe

date > /etc/vagrant_box_build_time

echo root:vagrant|chpasswd

apt-get install expect -y

expect -c "
    set timeout 100
    spawn su - root
    expect {
    \"password\" { send \"vagrant\n\"; }
    }
    expect eof
"

id

cat >> /etc/ssh/sshd_config <<EOF
UseDNS no
PasswordAuthentication yes
PermitRootLogin yes
EOF

echo 'Welcome to Vagrant-built virtual machine. -.-' > /var/run/motd

# Clean up
apt-get --yes autoremove
apt-get --yes clean

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm /var/lib/dhcp/*

echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
echo "pre-up sleep 2" >> /etc/network/interfaces
