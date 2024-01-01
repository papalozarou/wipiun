#!/bin/sh

#-------------------------------------------------------------------------------
# Starts all the containers.
# 
# N.B.
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Imported shared variables.
#-------------------------------------------------------------------------------
. ../linshafun/setup.var

#-------------------------------------------------------------------------------
# Imported shared functions.
#-------------------------------------------------------------------------------
. ../linshafun/comments.sh
# . ../linshafun/docker-env-variables.sh
# . ../linshafun/docker-images.sh
# . ../linshafun/docker-services.sh
# . ../linshafun/files-directories.sh
# . ../linshafun/firewall.sh
# . ../linshafun/host-env-variables.sh
# . ../linshafun/network.sh
. ../linshafun/ownership-permissions.sh
# . ../linshafun/packages.sh
# . ../linshafun/services.sh
. ../linshafun/setup-config.sh
. ../linshafun/setup.sh
# . ../linshafun/ssh-keys.sh
# . ../linshafun/text.sh
# . ../linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key.
#-------------------------------------------------------------------------------
CONFIG_KEY='wipiunStartedContainers'

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  echoComment 'Starting all containers.'
  docker compose up -d

  echoServiceWait 'all services' 'start' '45'

  echoSeparator
  docker compose ps -a
  echoSeparator
  
  echoComment 'All containers should now be started.'
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"