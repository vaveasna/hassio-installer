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

# ==============================================================================
# GLOBALS
# ==============================================================================
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

os_agent_version="";

# Set model list, begin ------------
 ARCHITECTURE_MODEL_LIST="
  # 1.architecture  
  386.tar.gz
  aarch64.deb
  amd64.tar.gz
  arm64.tar.gz
  armv5.deb
  armv5.tar.gz
  armv7.deb
  armv7.tar.gz
  i386.deb
  x86_64.deb
  "


# ==============================================================================
# SCRIPT LOGIC
# ==============================================================================



search_architecture_model() {
    local search_soc_id="${1}"
    local ret_count=$(echo "${ARCHITECTURE_MODEL_LIST}" | grep -E "^${search_soc_id}:" | wc -l)
    if [ "${ret_count}" -eq "1" ]; then
        echo "${ARCHITECTURE_MODEL_LIST}" | grep -E "^${search_soc_id}:" | sed -e 's/NA//g' -e 's/NULL//g' -e 's/[ ][ ]*//g'
    fi
}


# ------------------------------------------------------------------------------
# Installs the os-agent 
# ------------------------------------------------------------------------------
install_os-agent() {


  


  read -p "Please Input architecture: " boxtype

  ret=$(search_aml_model "${boxtype}")
  if [ "${ret}" == "" ]; then
      echo "Input error, exit!"
      exit 1
  fi

  os_agent_version=$(echo "${ret}" | awk -F ':' '{print $1}')
  
  exit 1

  echo "# ------------------------------------------------------------------------------"
  echo "Installing os-agent V${os_agent_version}..."
  echo "# ------------------------------------------------------------------------------"

  wget -c https://github.com/home-assistant/os-agent/releases/download/${os_agent_version}/os-agent_${os_agent_version}_linux_aarch64.deb

  echo "# ------------------------------------------------------------------------------"
  echo "dpkg os-agent V${os_agent_version}..."
  echo "# ------------------------------------------------------------------------------"
  dpkg -i os-agent_${os_agent_version}_linux_aarch64.deb


}




# ------------------------------------------------------------------------------
# Ensures the hostname of the Pi is correct.
# ------------------------------------------------------------------------------
update_hostname() {
  old_hostname=$(< /etc/hostname)
  if [[ "${old_hostname}" != "${HOSTNAME}" ]]; then
    sed -i "s/${old_hostname}/${HOSTNAME}/g" /etc/hostname
    sed -i "s/${old_hostname}/${HOSTNAME}/g" /etc/hosts
    hostname "${HOSTNAME}"
    echo "Hostname will be changed on next reboot: ${HOSTNAME}"
  fi
}

# ------------------------------------------------------------------------------
# Installs all required software packages and tools
# ------------------------------------------------------------------------------
install_requirements() {
  echo "# ------------------------------------------------------------------------------"
  echo "Updating APT packages list..."
  echo "# ------------------------------------------------------------------------------"
  apt-get clean
  rm -rf /var/lib/apt/lists/*
  apt-get clean
  apt --fix-broken install -Y
  apt-get update 
  apt-get upgrade
  apt-get install software-properties-common
  apt-get update
  echo "# ------------------------------------------------------------------------------"
  echo "Ensure all requirements are installed..."
  echo "# ------------------------------------------------------------------------------"
 
  apt-get install -y "${REQUIREMENTS[@]}"
 
  
}



# ------------------------------------------------------------------------------
# Installs the Docker engine
# ------------------------------------------------------------------------------
install_docker() {
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
}

# ------------------------------------------------------------------------------
# Installs and starts Hass.io
# ------------------------------------------------------------------------------
install_hassio() {
  echo "Installing Hass.io..."
  wget https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb
  dpkg -i homeassistant-supervised.deb
  sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y


}

# ------------------------------------------------------------------------------
# Configure network-manager to disable random MAC-address on Wi-Fi
# ------------------------------------------------------------------------------
config_network_manager() {
  {
    echo -e "\n[device]";
    echo "wifi.scan-rand-mac-address=no";
    echo -e "\n[connection]";
    echo "wifi.clone-mac-address=preserve";
  } >> "/etc/NetworkManager/NetworkManager.conf"
}

# ==============================================================================
# RUN LOGIC
# ------------------------------------------------------------------------------
main() {
  # Are we root?
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    echo "Please try again after running:"
    echo "  sudo su"
    exit 1
  fi

  # Install ALL THE THINGS!
  update_hostname
  install_requirements
  install_os-agent
  config_network_manager
  install_docker
  install_hassio

  # Friendly closing message
  ip_addr=$(hostname -I | cut -d ' ' -f1)
  echo "======================================================================="
  echo "Hass.io is now installing Home Assistant."
  echo "This process may take up to 20 minutes. Please visit:"
  echo "http://${HOSTNAME}.local:8123/ in your browser and wait"
  echo "for Home Assistant to load."
  echo "If the previous URL does not work, please try http://${ip_addr}:8123/"
  journalctl -f
  exit 0
}
main

