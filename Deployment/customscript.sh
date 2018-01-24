#!/bin/bash

declare hostname=""

# Initialize parameters specified from command line
while getopts ":h:" arg; do
	case "${arg}" in
		h)
			hostname=${OPTARG}
			;;
		esac
done
shift $((OPTIND-1))

# See: https://help.resilio.com/hc/en-us/articles/206178924-Installing-Sync-package-on-Linux
# on how to install resilio on Linux

# Upgrade to latest packages
apt update
apt upgrade -y

# add package source for resilio and install packages
echo "deb http://linux-packages.resilio.com/resilio-sync/deb resilio-sync non-free" | sudo tee /etc/apt/sources.list.d/resilio-sync.list
wget -qO - https://linux-packages.resilio.com/resilio-sync/key.asc | sudo apt-key add -
apt update
apt install resilio-sync -y 

# enable autostart for resilio
systemctl enable resilio-sync

# create partition table
parted /dev/sdc mktable gpt

# create partition
parted /dev/sdc mkpart primary ext4 "1 4397GB"

# format partition
mkfs.ext4 /dev/sdc1

# add partition to fstab
echo -e "\n/dev/sdc1\t/data\tauto\tdefaults\t0\t0" | tee -a /etc/fstab

# mount filesystem
mkdir /data
mount -a
chown rslsync:rslsync /data

# start resilio
systemctl start resilio-sync

# Now since resilio is running, we need to set up a https proxy to forward https requests to the internal resilio port 8888 with http.
# It is much more secure than just opening port 8888 to the world.

# Create a self signed certificate for ssl
openssl req -x509 -nodes -days 36500 -newkey rsa:2048 -keyout /tmp/ssl.key -out /tmp/ssl.crt -subj "/C=US/ST=CA/L=San Francisco/O=Snakeoil/OU=IT Department/CN=$hostname"
cat /tmp/ssl.crt /tmp/ssl.key > /etc/ssl/private/ssl.pem

# install haproxy to terminate ssl externaly and forward to resilio internally
add-apt-repository ppa:vbernat/haproxy-1.6 -y
apt update
apt install haproxy -y

# copy config file for haproxy
cp haproxy.cfg /etc/haproxy/

# enable haproxy for autostart
systemctl enable haproxy

# start haproxy
service haproxy start

# We are done!