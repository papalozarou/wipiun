#!/bin/sh

#-------------------------------------------------------------------------------
# Generates a script to update the root.hints file for unbound. This script
# is then be added as a cron job on the host machine, to run every six months.
# 
# N.B.
# This script needs to be run as "sudo".
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Imported shared variables.
#-------------------------------------------------------------------------------
. ../linshafun/setup.var

#-------------------------------------------------------------------------------
# Imported project specific variables.
#-------------------------------------------------------------------------------
. ./wipiun.var

#-------------------------------------------------------------------------------
# Imported shared functions.
#-------------------------------------------------------------------------------
. ../linshafun/comments.sh
# . ../linshafun/docker-env-variables.sh
. ../linshafun/docker-images.sh
# . ../linshafun/docker-services.sh
. ../linshafun/files-directories.sh
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
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='wipiunBuiltAlpineBaseImage'

#-------------------------------------------------------------------------------
# File variable.
#-------------------------------------------------------------------------------
COMPOSE_FILE=''

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  buildDockerImages 'compose.base.yml' 'alpine-base'
  listDockerImages
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"
