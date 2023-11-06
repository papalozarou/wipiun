#!/bin/sh

#-------------------------------------------------------------------------------
# Sets up wipiun by:
#
# 1. asking the user for a list of wireguard client machines;
# 2. checking and setting the container and VPN network IP addresses;
# 3. adding the wireguard port to UFW; and
# 3. building the wireguard and unbound images.
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
# . ../linshafun/network.sh
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
  promptForUserInput 'Please enter a comma separeted list of your wireguard clients.' 'This list must be comma separated.'
  WGD_CLIENTS="$(getUserInput)"
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  getWireguardClients

  setDockerEnvVariables "$DOCKER_ENV_FILE" 'C_WGD_CLIENTS' "$WGD_CLIENTS"

  checkAndSetDockerEnvVariables "$DOCKER_ENV_FILE" 'C_NW_PUBLIC' 'C_NW_VPN'

  addRuleToUfw 'allow' '51820' 'udp'
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
