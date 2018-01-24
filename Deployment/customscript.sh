#!/bin/bash

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

