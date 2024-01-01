#!/bin/sh

#-------------------------------------------------------------------------------
# Initialises the setup by:
#
# 1. updating and upgrading packages; 
# 2. checking for a config directory and file; and
# 3. preparing the service files by removing the ".example" postfix.
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
# . ../linshafun/docker-images.sh
# . ../linshafun/docker-services.sh
. ../linshafun/files-directories.sh
# . ../linshafun/firewall.sh
# . ../linshafun/host-env-variables.sh
# . ../linshafun/network.sh
. ../linshafun/ownership-permissions.sh
. ../linshafun/packages.sh
# . ../linshafun/services.sh
. ../linshafun/setup-config.sh
. ../linshafun/setup.sh
# . ../linshafun/ssh-keys.sh
# . ../linshafun/text.sh
# . ../linshafun/user-input.sh

#-------------------------------------------------------------------------------
# Config key variable.
#-------------------------------------------------------------------------------
CONFIG_KEY='initialisedWipiun'

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
# 
# N.B.
# Only one argument is passed to "removePostfixFromFiles" as the default for the
# second argument is "example".
#-------------------------------------------------------------------------------
mainScript () {
  updateUpgrade

  checkForSetupConfigFileAndDir

  copyAndRemovePostfixFromFiles "$WIPIUN_DIR"
  removeFileOrDirectory "$WIPIUN_DIR/setup/setup.conf"
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"