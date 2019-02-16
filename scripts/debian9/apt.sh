#!/bin/bash

error() {
        if [ $? -ne 0 ]; then
                printf "\n\napt failed...\n\n";
                exit 1
        fi
}

# To allow for autmated installs, we disable interactive configuration steps.
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# We handle name server setup later, but for now, we need to ensure valid resolvers are available.
printf "nameserver 114.114.114.114\nnameserver 1.2.4.8\nnameserver 8.8.8.8\n" > /etc/resolv.conf

# If the apt configuration directory exists, we add our own config options.
if [ -d /etc/apt/apt.conf.d/ ]; then

# Disable periodic activities of apt.
printf "APT::Periodic::Enable \"0\";\n" >> /etc/apt/apt.conf.d/10periodic

# Enable retries, which should reduce the number box buld failures resulting from a temporal network problems.
printf "APT::Periodic::Enable \"0\";\n" >> /etc/apt/apt.conf.d/20retries

fi

# Keep the daily apt updater from deadlocking our installs.
systemctl stop apt-daily.service apt-daily.timer

# Rewrite source.
#sed -i -e "/cdrom:/d" /etc/apt/sources.list
cat > /etc/apt/sources.list <<EOF
deb http://mirrors.aliyun.com/debian/ stretch main non-free contrib
deb-src http://mirrors.aliyun.com/debian/ stretch main non-free contrib
deb http://mirrors.aliyun.com/debian-security stretch/updates main
deb-src http://mirrors.aliyun.com/debian-security stretch/updates main
deb http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib
deb-src http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib
deb http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib
deb-src http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib
EOF


# Ensure the server includes any necessary updates.
apt-get --assume-yes -o Dpkg::Options::="--force-confnew" update; error
apt-get --assume-yes -o Dpkg::Options::="--force-confnew" upgrade; error
apt-get --assume-yes -o Dpkg::Options::="--force-confnew" dist-upgrade; error

# The packages users expect on a sane system.
apt-get --assume-yes install vim net-tools mlocate psmisc; error

# The packages needed to compile magma.
apt-get --assume-yes install gcc g++ gawk gcc-multilib make autoconf automake libtool flex bison gdb valgrind valgrind-dbg libpython2.7 libc6-dev libc++-dev libncurses5-dev libmpfr4 libmpfr-dev patch make cmake libarchive13 libbsd-dev libsubunit-dev libsubunit0 pkg-config lsb-release; error

# The memcached server.
apt-get --assume-yes install memcached libevent-dev; error

# The postfix server for message relays.
apt-get --assume-yes install postfix postfix-cdb libcdb1 ssl-cert; error

# Need to retrieve the source code.
apt-get --assume-yes install git git-man liberror-perl rsync wget; error

# Needed to run the watcher and status scripts.
apt-get --assume-yes install sysstat inotify-tools; error

# Needed to run the stacie script.
apt-get --assume-yes install python-crypto python-cryptography; error

# Upgrade linux kernel
apt-get --assume-yes install -t stretch-backports linux-image-amd64

# Boosts the available entropy which allows magma to start faster.
apt-get --assume-yes install haveged; error