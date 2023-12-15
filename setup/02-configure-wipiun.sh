#!/bin/sh

#-------------------------------------------------------------------------------
# Sets up wipiun by:
#
# 1. generating and setting the server port for wireguard;
# 2. asking the user for a list of wireguard client machines;
# 3. checking and setting the container and VPN network IP addresses;
# 4. adding the wireguard port to UFW; and
# 5. building the wireguard and unbound images.
# 
# N.B.
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Imported shared variables.
#-------------------------------------------------------------------------------
. ../linshafun/setup.var
. ../linshafun/docker.var

#-------------------------------------------------------------------------------
# Imported shared functions.
#-------------------------------------------------------------------------------
. ../linshafun/comments.sh
. ../linshafun/docker-env-variables.sh
. ../linshafun/docker-images.sh
# . ../linshafun/docker-services.sh
# . ../linshafun/files-directories.sh
. ../linshafun/firewall.sh
# . ../linshafun/host-env-variables.sh
. ../linshafun/network.sh
. ../linshafun/ownership-permissions.sh
# . ../linshafun/packages.sh
. ../linshafun/services.sh
. ../linshafun/setup-config.sh
. ../linshafun/setup.sh
# . ../linshafun/ssh-keys.sh
# . ../linshafun/text.sh
. ../linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='configuredWipiun'

#-------------------------------------------------------------------------------
# Get a comma separated list of wireguard clients.
#-------------------------------------------------------------------------------                    
getWireguardClients () {
  promptForUserInput 'Please enter a comma separeted list of your wireguard clients.' 'This list must be comma separated with no spaces, i.e.' 'clientName1,clientName2,clientName3'
  WGD_CLIENTS="$(getUserInput)"
}

#-------------------------------------------------------------------------------
# Sets the server port for wireguard. Checks against rtorrent and plex ports to 
# see if the generated port is the same. If not replace the port number in the 
# ".env" file and write the port to the setup config file. If it matches, re-run
# this function.
#-------------------------------------------------------------------------------
setWireguardServerPort () {
  local WGD_PORT="$(generateAndCheckPort "ssh")"
  local RTT_PORT_CHECK_TF="$(checkAgainstExistingPortNumber "rtt")"
  local PLEX_PORT="32400"

  if [ "$RTT_PORT_CHECK_TF" = true ] || [ "$WGD_PORT" = "$PLX_PORT" ]; then
    setWireguardServerPort
  fi

  setDockerEnvVariables "$DOCKER_ENV_FILE" 'C_WGD_SERVER_PORT' "$WGD_PORT"
  
  writeSetupConfigOption "wgdPort" "WGD_PORT"
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  setWireguardServerPort

  getWireguardClients

  setDockerEnvVariables "$DOCKER_ENV_FILE" 'C_WGD_CLIENTS' "$WGD_CLIENTS"

  checkAndSetDockerEnvVariables "$DOCKER_ENV_FILE" 'C_NW_PUBLIC' 'C_NW_VPN'

  addRuleToUfw 'allow' '51820' 'udp'
  addRuleToUfw 'allow' '53' 'udp'
  listUfwRules
  controlService 'ufw' 'restart'

  buildDockerImages "$WIPIUN_DIR/$DOCKER_COMPOSE_FILE" 'wireguard' 'unbound'
  listDockerImages
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"

