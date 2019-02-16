#!/bin/bash -eux

# To allow for autmated installs, we disable interactive configuration steps.
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Disable IPv6 for the current boot.
sysctl net.ipv6.conf.all.disable_ipv6=1

# Ensure IPv6 stays disabled.
printf "\nnet.ipv6.conf.all.disable_ipv6 = 1\n" >> /etc/sysctl.conf

# Set the hostname, and then ensure it will resolve properly.
printf "ysicing.local\n" > /etc/hostname
printf "\n127.0.0.1 yscing.local\n\n" >> /etc/hosts


# Clear out the existing automatic ifup rules.
sed -i -e '/^auto/d' /etc/network/interfaces
sed -i -e '/^iface/d' /etc/network/interfaces
sed -i -e '/^allow-hotplug/d' /etc/network/interfaces

# Ensure the loopback, and default network interface are automatically enabled and then dhcp'ed.
printf "allow-hotplug eth0\n" >> /etc/network/interfaces
printf "auto lo\n" >> /etc/network/interfaces
printf "iface lo inet loopback\n" >> /etc/network/interfaces
printf "iface eth0 inet dhcp\n" >> /etc/network/interfaces
printf "dns-nameserver 114.114.114.114\n" >> /etc/network/interfaces
printf "dns-nameserver 1.2.4.8\n" >> /etc/network/interfaces
printf "dns-nameserver 8.8.8.8\n" >> /etc/network/interfaces

# Adding a delay so dhclient will work properly.
printf "pre-up sleep 2\n" >> /etc/network/interfaces

# Ensure a nameserver is being used that won't return an IP for non-existent domain names.
printf "nameserver 114.114.114.114\nnameserver 1.2.4.8\nnameserver 8.8.8.8\n" > /etc/resolv.conf

# Install ifplugd so we can monitor and auto-configure nics.
apt-get --assume-yes install ifplugd resolvconf

# Configure ifplugd to monitor the eth0 interface.
sed -i -e 's/INTERFACES=.*/INTERFACES="eth0"/g' /etc/default/ifplugd

# Ensure the networking interfaces get configured on boot.
systemctl enable networking.service

# Ensure ifplugd also gets started, so the ethernet interface is monitored.
systemctl enable ifplugd.service

# Ensure a sane DNSS configuration.
systemctl enable resolvconf.service

# Reboot onto the new kernel (if applicable).
$(shutdown -r +1) &
