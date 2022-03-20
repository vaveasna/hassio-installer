#!/usr/bin/env bash
###################################################################
###################################################################
##                                                               ##
## THIS SCRIPT SHOULD ONLY BE RUN ON A S9xxx BOX RUNNING ARMBIAN ##
##                                                               ##
###################################################################
###################################################################


set -o errexit  # Exit script when a command exits with non-zero status
set -o errtrace # Exit on error inside any functions or sub-shells
set -o nounset  # Exit script on use of an undefined variable
set -o pipefail # Return exit status of the last command in the pipe that failed
#
## ==============================================================================
## GLOBALS
## ==============================================================================
readonly HOSTNAME="TV4YOU"
readonly REQUIREMENTS=(
  apparmor-utils
  apt-transport-https
  avahi-daemon
  ca-certificates
  curl
  dbus
  jq
  network-manager
  socat
  software-properties-common
  udisks2 
  wget
)

os_agent_version="1.2.2"


# ==============================================================================
# SCRIPT LOGIC
# ==============================================================================
sudo apt update && sudo apt upgrade

sudo apt install gcc-8-base

rm -f etc/apt/sources.list

cat >etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian bullseye main contrib non-free
deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb http://security.debian.org/debian-security bullseye-security main
deb http://ftp.debian.org/debian bullseye-backports main contrib non-free
EOF

sudo apt update

sudo apt full-upgrade


# ==============================================================================
# Are we root?
# ==============================================================================
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  echo "Please try again after running:"
  echo "  sudo su"
  exit 1
fi

# ------------------------------------------------------------------------------
# Ensures the hostname of the Pi is correct.
# ------------------------------------------------------------------------------
old_hostname=$(< /etc/hostname)
if [[ "${old_hostname}" != "${HOSTNAME}" ]]; then
  sed -i "s/${old_hostname}/${HOSTNAME}/g" /etc/hostname./
  sed -i "s/${old_hostname}/${HOSTNAME}/g" /etc/hosts
  hostname "${HOSTNAME}"
  echo "Hostname will be changed on next reboot: ${HOSTNAME}"
fi


echo "# ------------------------------------------------------------------------------"
echo "Updating APT packages list..."
echo "# ------------------------------------------------------------------------------"
apt-get clean
rm -rf /var/lib/apt/lists/*
apt-get clean
apt --fix-broken install -y
apt-get update 
apt-get upgrade
apt-get install software-properties-common
apt-get update

echo "# ------------------------------------------------------------------------------"
echo "Ensure all requirements are installed..."
echo "# ------------------------------------------------------------------------------"
apt-get install -y "${REQUIREMENTS[@]}"
 

# Set model list, begin ------------
ARCHITECTURE_MODEL_LIST="
# 1.Architecture
1:linux_386.tar.gz
2:linux_aarch64.deb
3:linux_amd64.tar.gz
4:linux_arm64.tar.gz
5:linux_armv5.deb
6:linux_armv5.tar.gz
7:linux_armv7.deb
8:linux_armv7.tar.gz
9:linux_i386.deb
10:linux_x86_64.deb
"

search_architecture() {
    local search_soc_id="${1}"
    local ret_count=$(echo "${ARCHITECTURE_MODEL_LIST}" | grep -E "^${search_soc_id}:" | wc -l)
    if [ "${ret_count}" -eq "1" ]; then
        echo "${ARCHITECTURE_MODEL_LIST}" | grep -E "^${search_soc_id}:" | sed -e 's/NA//g' -e 's/NULL//g' -e 's/[ ][ ]*//g'
    fi
}

# Display the ARCHITECTURE list
printf "%-s\n" "--------------------------------------------------------------------------------------"
printf "%-5s %-10s \n" ID   ARCHITECTURE
printf "%-s\n" "--------------------------------------------------------------------------------------"
printf "%-5s %-10s \n" $(echo "${ARCHITECTURE_MODEL_LIST}" | grep -E "^[0-9]{1,9}:" | sed -e 's/[ ][ ]*/-/g' | awk -F ':' '{print $1,$3,$2,$4}')
printf "%-s\n" "--------------------------------------------------------------------------------------"


 

read -p "Please Input ID: " boxtype

ret=$(search_architecture "${boxtype}")
if [ "${ret}" == "" ]; then
    echo "Input error, exit!"
    exit 1
fi

ARCHITECTURE=$(echo "${ret}" | awk -F ':' '{print $2}')

# Set model ARCHITECTURE, end ------------

# ------------------------------------------------------------------------------
# Installs the os-agent 
# ------------------------------------------------------------------------------

echo "# ------------------------------------------------------------------------------"
echo "Installing os-agent ${ARCHITECTURE}  V:${os_agent_version}..."
echo "# ------------------------------------------------------------------------------"
exit 1
wget -c https://github.com/home-assistant/os-agent/releases/download/${os_agent_version}/os-agent_${os_agent_version}_${ARCHITECTURE}

echo "# ------------------------------------------------------------------------------"
echo "dpkg os-agent V${os_agent_version}..."
echo "# ------------------------------------------------------------------------------"
dpkg -i os-agent_${os_agent_version}_${ARCHITECTURE}

{
  echo -e "\n[device]";
  echo "wifi.scan-rand-mac-address=no";
  echo -e "\n[connection]";
  echo "wifi.clone-mac-address=preserve";
} >> "/etc/NetworkManager/NetworkManager.conf"

# ------------------------------------------------------------------------------
# Installing Docker...
# ------------------------------------------------------------------------------
echo "# ------------------------------------------------------------------------------"
echo "Installing Docker..."
echo "# ------------------------------------------------------------------------------"
curl -fsSL https://get.docker.com | sh


# ------------------------------------------------------------------------------
# Installs and starts Hass.io
# ------------------------------------------------------------------------------
echo "# ------------------------------------------------------------------------------"
echo "Installing Hass.io..."
echo "# ------------------------------------------------------------------------------"
wget https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb

dpkg -i homeassistant-supervised.deb

sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y


# Friendly closing message
ip_addr=$(hostname -I | cut -d ' ' -f1)
echo "======================================================================="
echo "Hass.io is now installing Home Assistant."
echo "This process may take up to 20 minutes. Please visit:"
echo "http://${HOSTNAME}.local:8123/ in your browser and wait"
echo "for Home Assistant to load."
echo "If the previous URL does not work, please try http://${ip_addr}:8123/"
journalctl -f



