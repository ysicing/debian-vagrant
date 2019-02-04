#!/bin/sh

set -e

if [ $1 ]; then
  fs=$1
elif [ $VAGRANT_BUILDER_FS ]; then
  fs=$VAGRANT_BUILDER_FS
else
  echo "usage: $0 ROOTFS [HOSTNAME]";
  exit 1
fi

if [ $2 ]; then
  hostname=$2
elif [ $VAGRANT_BUILDER_HOSTNAME ]; then
  hostname=$VAGRANT_BUILDER_HOSTNAME
fi

set -x

#######################################################################
# Debconf Dialog frontend does not work without a controlling terminal
# We restore this in the end
#######################################################################
echo 'debconf debconf/frontend select Noninteractive' | \
	chroot $fs debconf-set-selections

#######################################################################
# upgrade Debian images as the LXC template does not do it.
#######################################################################
printf '#!/bin/sh\nexit 101\n' > $fs/usr/sbin/policy-rc.d
chmod +x $fs/usr/sbin/policy-rc.d
echo 'Acquire::Languages "none";' > $fs/etc/apt/apt.conf.d/99translations
chroot $fs apt-get update
chroot $fs apt-get -qy dist-upgrade

#######################################################################
# install packages from the 'important' and 'standard' sets
#######################################################################
chroot $fs apt-get install -qy dctrl-tools
chroot $fs grep-aptavail --no-field-names --show-field Package --field Priority --regex 'standard\|important' \
  | chroot $fs xargs apt-get install -qy pinentry-curses
  # avoid gnupg-agent pulling pinentry-gtk2 on jessie_|
chroot $fs apt-get purge -qy dctrl-tools

#######################################################################
# setup vagrant user
#######################################################################
chroot $fs id ubuntu >/dev/null 2>&1 && chroot $fs deluser ubuntu
chroot $fs id vagrant >/dev/null 2>&1 || chroot $fs useradd --create-home --uid 1000 --shell /bin/bash vagrant
mkdir -p $fs/home/vagrant/.ssh
chmod 700 $fs/home/vagrant/.ssh
cat > $fs/home/vagrant/.ssh/authorized_keys << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
EOF
chmod 600 $fs/home/vagrant/.ssh/authorized_keys
chroot $fs chown -R vagrant:vagrant /home/vagrant/.ssh

#######################################################################
# setup passwordless sudo for vagrant user
#######################################################################
chroot $fs apt-get install -qy sudo
cat > $fs/etc/sudoers.d/vagrant <<EOF
vagrant ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 $fs/etc/sudoers.d/vagrant

#######################################################################
# setup hostname
#######################################################################
if [ -n "$hostname" ]; then
  echo "${hostname%%.*}" > $fs/etc/hostname
fi

#######################################################################
# speed up tweaks
#######################################################################

# Prevent DNS resolution (speed up logins)
echo 'UseDNS no' >> $fs/etc/ssh/sshd_config
# Disable password logins
echo 'PasswordAuthentication no' >> $fs/etc/ssh/sshd_config

# Reduce grub timeout to 1s to speed up booting
[ -f $fs/etc/default/grub ] && \
  sed -i s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/ $fs/etc/default/grub

# Updating grub config right now is only safe if we are not in a chroot
# otherwise  grub complains on the lack of a mounted /
[ -x $fs/usr/sbin/update-grub ] && \
  chroot $fs mountpoint -q /dev/ && \
  chroot $fs /usr/sbin/update-grub

#######################################################################
# cleanup
#######################################################################
chroot $fs apt-get clean
rm -f $fs/usr/sbin/policy-rc.d
echo 'debconf debconf/frontend select Dialog' | \
    chroot $fs debconf-set-selections

# make sure /etc/machine-id is generated on next book
# /etc/machine-id needs to be unique so multiple systemd-networkd dhcp clients
# get different ip addresses from the DHCP server
rm $fs/var/lib/dbus/machine-id
> $fs/etc/machine-id
