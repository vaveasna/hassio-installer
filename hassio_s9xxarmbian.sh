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
readonly HOSTNAME="Hass"
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
  python3 
  python3-dev 
  python3-pip 
  python3-venv
  libglib2.0-bin
  systemd-journal-remote
  systemd-resolved
)

os_agent_version="1.6.0"
ARCHITECTURE="linux_aarch64.deb"

# ==============================================================================
# SCRIPT LOGIC
# ==============================================================================


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
  sed -i "s/${old_hostname}/${HOSTNAME}/g" /etc/hostname
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
apt-get upgrade -y
apt-get install -y software-properties-common
apt-get update

echo "# ------------------------------------------------------------------------------"
echo "Ensure all requirements are installed..."
echo "# ------------------------------------------------------------------------------"
apt-get install -y "${REQUIREMENTS[@]}"
 

# ------------------------------------------------------------------------------
# Installs the os-agent 
# ------------------------------------------------------------------------------

echo "# ------------------------------------------------------------------------------"
echo "Installing os-agent ${ARCHITECTURE}  V:${os_agent_version}..."
echo "# ------------------------------------------------------------------------------"

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

docker pull ghcr.io/home-assistant/aarch64-hassio-supervisor:2025.01.0

# ------------------------------------------------------------------------------
# Installs and starts Hass.io
# ------------------------------------------------------------------------------
echo "# ------------------------------------------------------------------------------"
echo "Installing Hass.io..."
echo "# ------------------------------------------------------------------------------"
wget https://github.com/Travis90x/supervised-installer/releases/latest/download/homeassistant-supervised.deb

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




