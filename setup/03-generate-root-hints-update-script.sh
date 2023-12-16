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
# . ../linshafun/docker-images.sh
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
CONFIG_KEY='generatedRootHintsUpdateScript'

#-------------------------------------------------------------------------------
# File variable.
#-------------------------------------------------------------------------------
ROOT_HINTS_UPDATE_SCRIPT="$WIPIUN_DIR/update-root-hints.sh"
ROOT_HINTS_UPDATE_SCHEDULE="/etc/cron.d/update-root-hints"

#-------------------------------------------------------------------------------
# Adds the previously generated update script to the system's crontab.
#-------------------------------------------------------------------------------
addPlexUpdateScriptToCrond () {
  echoComment 'Adding the generated update script to the system crontab.'
  su -c 'echo "0 3 1 */6 * root '"$ROOT_HINTS_UPDATE_SCRIPT"'" > '"$ROOT_HINTS_UPDATE_SCHEDULE"''
  
  echoComment 'Script added.'
}

#-------------------------------------------------------------------------------
# Generates the update script, which  for adding to crontab.
#-------------------------------------------------------------------------------
generateRootHintsUpdateScript () {
  echoComment 'Generating root hints update file at:' 
  echoComment "$ROOT_HINTS_UPDATE_SCRIPT" 
  cat <<EOF > "$ROOT_HINTS_UPDATE_SCRIPT"
#!/bin/sh

# ------------------------------------------------------------------------------
# Script to run as root, via cron, every six months to update the root.hints 
# file for unbound.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Run simple apline linux container and download latest root.hints file.
# ------------------------------------------------------------------------------
docker run --rm -v wipiun_ubd_data:/etc/unbound --workdir /etc/unbound alpine:latest wget -S https://www.internic.net/domain/named.cache -O root.hints
EOF
  echoComment 'Script generated.'
}

#-------------------------------------------------------------------------------
# Executes the main functions of the script.
#-------------------------------------------------------------------------------
mainScript () {
  generateRootHintsUpdateScript
  setPermissions '700'  "$ROOT_HINTS_UPDATE_SCRIPT"
  setOwner "$SUDO_USER" "$ROOT_HINTS_UPDATE_SCRIPT"
  listDirectories "$ROOT_HINTS_UPDATE_SCRIPT"

  addRootHintsUpdateScriptToCrond
  setPermissions '600' "$ROOT_HINTS_UPDATE_SCHEDULE"
  listDirectories "$ROOT_HINTS_UPDATE_SCHEDULE"
}

#-------------------------------------------------------------------------------
# Run the script.
#-------------------------------------------------------------------------------
initialiseScript "$CONFIG_KEY"
mainScript
finaliseScript "$CONFIG_KEY"