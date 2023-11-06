#!/bin/sh

# ------------------------------------------------------------------------------
# Script to set up Wireguard on container first run.
#
# N.B.
# Wireguard kernal module is assumed to be active on the host machine. If it is 
# not you must install it. It is present on most modern linux installs.
# ------------------------------------------------------------------------------

****** REMEMBER WE'RE USING sh not bash and that it's PUID and GUID ******

addClientToServerConf () {

}

addServerAllowedIps () {

}

generateClientConfig () {

}

generateClientConfigs () {

}

generateClientKeys()  {
  
}

generateClientQrCode () {
  
}

generateServerConf () {

}

# ------------------------------------------------------------------------------
# Generates "$CLIENTS" using value of docker env variable "$CLIENTS".
# ------------------------------------------------------------------------------
getClients () {

}

# ------------------------------------------------------------------------------
# Removes any existing configurations in "etc/wireguard" and symlinks to a
# config in "$USER_DIR/config".
# ------------------------------------------------------------------------------
prepFolderAndSymlink () {

}

# ------------------------------------------------------------------------------
# Copy the default templates to the "$USER_DIR/config" directory for use later
# if they don't already exist.
# ------------------------------------------------------------------------------
prepTemplates () {

}

saveDockerEnvVariables () {

}

# ------------------------------------------------------------------------------
# Checks to see if "$CLIENT_DNS" is blank or set to "auto" and if true sets it
# to the host's DNS.
# ------------------------------------------------------------------------------
setClientDns () {

}

setClientIp () {

}

setClientName () {

}

# ------------------------------------------------------------------------------
# Checks to see if "$SERVER_URL" is a blank string and if true sets it to the
# server IP address.
# ------------------------------------------------------------------------------
setServerUrl () {

}

testAllowedIps () {
  
}

testClientDns () {

}

testClientsOrInterface () {

}

testServerUrlOrPort () {

}

****** REMEMBER WE'RE USING sh not bash and that it's PUID and GUID ******