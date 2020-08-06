#!/usr/bin/env bash

# This script install Python 3.7 in your Ubuntu System
#
# This script must be run as root:
# sudo sh install_python3.sh
#

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Installing python 3.7
apt-get update
apt-get install python3.7

# Adding config and previous installation as alternatives
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 2

# Setting alternative: select 2
sudo update-alternatives --config python3

# Testing
python3 -V

# Upgrading pip3 as well
sudo -H pip3 install --upgrade pip
pip3 -V
