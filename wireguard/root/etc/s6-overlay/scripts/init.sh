#!/command/with-contenv bash

# ------------------------------------------------------------------------------
# Script to set up Wireguard on container first run.
#
# N.B.
# Wireguard kernal module is assumed to be active on the host machine. If it is 
# not you must install it.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Removes any existing configurations in "/etc/wireguard" and symlinks to a
# config in "/config".
# ------------------------------------------------------------------------------
preFolderAndSymlink () {
  echo "Wireguard setup: Initialising /config, /etc/wireguard and symlinking /config/wg0.conf -> /etc/wireguard/wg0.conf"
  
  mkdir -p /config/{server,templates}

  rm -rf /etc/wireguard
  mkdir -p /etc/wireguard
  ln -s /config/wg0.conf /etc/wireguard/wg0.conf
}

# ------------------------------------------------------------------------------
# Copy the default templates to the '/config' directory for use later if they
# don't already exist.
# ------------------------------------------------------------------------------
prepTemplates () {
  echo "Wireguard setup: Copying templates."

  [[ ! -f /config/templates/server.conf ]] && \
  cp /defaults/server.conf /config/templates/server.conf

  [[ ! -f /config/templates/client.conf ]] && \
    cp /defaults/client.conf /config/templates/client.conf
}

# ------------------------------------------------------------------------------
# Generate "$CLIENTS_ARRAY" using value of docker env variable "$CLIENTS", by 
# testing to see if "$CLIENTS" is a number, then setting the array accordingly.
# ------------------------------------------------------------------------------
getClientsArray () {  
  if [[ "${CLIENTS}" =~ ^[0-9]+$ ]]; then
    CLIENTS_ARRAY=($(seq 1 ${CLIENTS}))
  else
    CLIENTS_ARRAY=($(echo "${CLIENTS}" | tr ',' ' '))
  fi

  CLIENTS_COUNT=$(echo "${#CLIENTS_ARRAY[@]}")
  echo "Wireguard setup: There are $CLIENTS_COUNT clients: ${CLIENTS_ARRAY[@]}"
  
  return $CLIENTS_ARRAY
}

# ------------------------------------------------------------------------------
# Checks to see if '$SERVER_IP' is a blank string and if true sets it to the
# server IP address.
# ------------------------------------------------------------------------------
setServerURL () {
  if [[ -z "$SERVER_URL" ]] || [[ "$SERVER_URL" = "auto" ]]; then
    SERVER_URL=$(curl -s icanhazip.com)
    echo "Wireguard setup: SERVER_URL is not set or set to \"auto\" – setting to external IP."
  else
    echo "Wireguard setup: External server address is set to $SERVER_URL."
  fi
}

# ------------------------------------------------------------------------------
# Checks to see if "$CLIENT_DNS" is blank or set to "auto" and if true sets it 
# to the host's DNS.
# ------------------------------------------------------------------------------
setClientDNS () {
  if [[ -z "$CLIENT_DNS" ]] || [[ "$CLIENT_DNS" = "auto" ]]; then
    CLIENT_DNS="${INTERACE}.1"
    echo "Wireguard setup: CLIENT_DNS is not set or set to \"auto\" – setting to ${INTERFACE}.1 to use wireguard docker host's DNS."
  else
    echo "Wireguard setup: Client DNS will be set to ${CLIENT_DNS}."
  fi
}

# ------------------------------------------------------------------------------
# Generate the server config by:
# 
# 1. Checking to see if a private key file exists, if not, generate both 
#    private and public key files with permissions of "700" via "unmask 077".
# 2. Populate the "wg0.conf" from the above "server.conf" template – clients 
#    will be added later.
# ------------------------------------------------------------------------------
generateServerConf () {
  echo "Wireguard setup: Generating server config file."

  if [[ ! -f /config/server/privatekey-server ]]; then
    umask 077
    wg genkey | tee /config/server/privatekey-server | wg pubkey > /config/server/publickey-server
  fi

  eval "`printf %s` cat <<EOF > /config/wg0.conf 
`cat /config/templates/server.conf` 
EOF"
}

# ------------------------------------------------------------------------------
# Check for client pub/private keys and generate if required.
#
# N.B.
# "${1}" is "${CLIENT_NAME}" passed in – bash scripts reference arguements 
# passed
# into functions by position, with ${0} being the function itself.
# 
# Taken from:
#
# - https://stackoverflow.com/questions/6212219/passing-parameters-to-a-bash-function
# ------------------------------------------------------------------------------
generateClientKeys () {
    if [[ ! -f "/config/${1}/privatekey-${1}" ]]; then
      umask 077

      wg genkey | tee /config/${1}/privatekey-${1} | wg pubkey > /config/${1}/publickey-${1}
      wg genpsk > /config/${1}/presharedkey-${1}
    fi
}

# ------------------------------------------------------------------------------
# Check if "CLIENT_NAME" is a number or string. If it's a number return it as 
# "clientX" and if it's a string return it as "client_$[string]".
# 
# Requires current index of "$CLIENT_ARRAY" ("${1}") to be passed in.
# ------------------------------------------------------------------------------
setClientName () {
  if [[ "${1}" =~ ^[0-9]+$ ]]; then
    CLIENT_NAME="client${1}"
  else 
    CLIENT_NAME="client_${1//[^[:alnum:]_-]/}"
  fi

  echo $CLIENT_NAME
}

# ------------------------------------------------------------------------------
# Sets the "$CLIENT_IP" for each client by checking if:
# 
# - a client config exists AND "$ORIG_INTERFACE" isn't null AND "$INTERFACE 
#   isn't equal to "$ORIG_INTERFACE"; or
# - a client config exists; or
# - any other situation.
# 
# Requires "$CLIENT_NAME" ("${1}") to be passed in.
# ------------------------------------------------------------------------------
setClientIP () {
  for idx in {2..254}; do
    PROPOSED_CLIENT_IP="${INTERFACE}.${idx}"

    if ! grep -q -R "$PROPOSED_CLIENT_IP" /config/client*/*.conf && ([ -z "${ORIG_INTERFACE}" ] || ! grep -q -R "${ORIG_INTERFACE}.${idx}" /config/client*/*.conf ); then
      CLIENT_IP="${PROPOSED_CLIENT_IP}"

      break   
    elif [[ -f "/config/${1}/${1}.conf" ]] && [[ -n "${ORIG_INTERFACE}" ]] && [[ "${INTERFACE}" != "${ORIG_INTERFACE}" ]]; then
      CLIENT_IP=$(echo "${CLIENT_IP}" | sed "s|${ORIG_INTERFACE}|${INTERFACE}|")
    else
      CLIENT_IP=$(cat /config/${1}/${1}.conf | grep "Address" | awk '{print $NF}')
    fi
  done

  echo: "Client ip is ${CLIENT_IP}."

  echo $CLIENT_IP
}

# ------------------------------------------------------------------------------
# Generates a config file for the client at /config/client_$CLIENT_NAME.
# 
# Requires "$CLIENT_NAME" ("${1}") to be passed in.
# ------------------------------------------------------------------------------
createClientConf () {
  eval "`printf %s` cat <<EOF > /config/${1}/${1}.conf 
`cat /config/templates/client.conf` 
EOF"
}

# ------------------------------------------------------------------------------
# Generates a QR code PNG for each client, displaying it within the terminal
# and saving it to /config/client_$CLIENT_NAME.
# 
# Requires "$CLIENT_NAME" ("${1}") to be passed in.
# ------------------------------------------------------------------------------
createClientQRCode () {
  if [ -z "${LOG_CONFS}" ] || [ "${LOG_CONFS}" = "true" ]; then
    echo "Wireguard setup: - QR code for ${CLIENT_NAME}:"
    qrencode -t ansiutf8 < /config/${1}/${1}.conf
  fi

  qrencode -o /config/${1}/${1}.png < /config/${1}/${1}.conf
  echo "Wireguard setup: - QR code png for ${1} saved in /config/${1}."
}

# ------------------------------------------------------------------------------
# Adds the allowed IPs for the client to "wg0.conf". 
# 
# Requires "$CLIENT_NAME" ("${1}") and "$CLIENT_IP" ("${2}") to be passed in 
# in that order.
# ------------------------------------------------------------------------------
addServerAllowedIPs () {
    SERVER_ALLOWED_IPS=SERVER_ALLOWED_IPS_CLIENT_${1}

    if [[ -n "${!SERVER_ALLOWED_IPS}" ]]; then      
      cat << EOP >> /config/wg0.conf
AllowedIPs = ${2}/32,${!SERVER_ALLOWED_IPS}
EOP
    else
      cat << EOP >> /config/wg0.conf
AllowedIPs = ${2}/32
EOP
    fi
}

# ------------------------------------------------------------------------------
# Adds the peer config to the server config file.
# 
# Requires "$CLIENT_NAME" ("${1}") to be passed in.
# ------------------------------------------------------------------------------
addClientToServerConf () {
  cat <<EOP >> /config/wg0.conf
[Peer]
# ${1}
PublicKey = $(cat /config/${1}/publickey-${1})
PresharedKey = $(cat /config/${1}/presharedkey-${1})
EOP
}

# ------------------------------------------------------------------------------
# Generates all configs needed for clients, including adding them to "wg0.conf".
#
# This is done by looping through "$CLIENTS_ARRAY" and, for each client:
# 
# 1. Setting the client name;
# 2. creating a directory;
# 2. generating pub/private keys;
# 3. adding the client ip;
# 4. adding the public key and any preshared key to the client config;
# 5. adding the above to the server config; and
# 6. adding the allowed IPs to the client and server configs.
# ------------------------------------------------------------------------------
generateClientConfs () {
  echo "Wireguard setup: Generating client config files."

  for i in ${CLIENTS_ARRAY[@]}; do
    echo "Wireguard setup: Generating client config for ${i}:"

    CLIENT_NAME=$(setClientName "${i}")
    echo "Wireguard setup: - Setting name to ${CLIENT_NAME}."

    mkdir -p /config/${CLIENT_NAME}
    echo "Wireguard setup: - Creating directory at /config/${CLIENT_NAME}."

    generateClientKeys ${CLIENT_NAME}
    echo "Wireguard setup: - Generating client public and private keys."

    CLIENT_IP=$(setClientIP "$CLIENT_NAME")

    createClientConf ${CLIENT_NAME}
    echo "Wireguard setup: - Creating config file /config/client_${CLIENT_NAME}."

    addClientToServerConf ${CLIENT_NAME}
    echo "Wireguard setup: - Adding ${CLIENT_NAME} to server config."

    addServerAllowedIPs ${CLIENT_NAME}  ${CLIENT_IP}
    echo "Wireguard setup: - Adding client's allowed IPs to server conf."

    createClientQRCode ${CLIENT_NAME}

  done
}

# ------------------------------------------------------------------------------
# Saves original values of all docker env variables to 
# ".dont-touch-this-do-do-do-do" for comparison later.
# ------------------------------------------------------------------------------
saveDockerEnvVariables () {
  echo "Wireguard setup: Saving docker env variables to file."
  cat <<EOF > /config/.dont-touch-this-do-do-do-do
ORIG_SERVER_URL="$SERVER_URL"
ORIG_SERVER_PORT="$SERVER_PORT"
ORIG_CLIENT_DNS="$CLIENT_DNS"
ORIG_CLIENTS="$CLIENTS"
ORIG_INTERFACE="$INTERFACE"
ORIG_ALLOWED_IPS="$ALLOWED_IPS"
EOF
}

# ------------------------------------------------------------------------------
# Test to see if "$CLIENTS" or "$INTERFACE" have changed. These are done 
# together as they require a regeneration of all config files.
# ------------------------------------------------------------------------------
testClientsOrInterface () {
  if [[ "$CLIENTS" != "$ORIG_CLIENTS" ]] || [[ "$INTERFACE" != "$ORIG_INTERFACE" ]]; then
    echo "Wireguard setup: CLIENTS and/or INTERFACE has changed – regenerating client configs."

    generateServerConf
    generateClientConfs

    saveDockerEnvVariables
  else
    echo "Wireguard setup: No changes to CLIENTS and/or INTERFACE – existing configs will be used."
  fi
}

# ------------------------------------------------------------------------------
# Test to see if "$SERVER_URL" or "$SERVER_PORT" have changed, if so update and 
# update configs.
# ------------------------------------------------------------------------------
testServerURLOrPort () {
  if [[ "$SERVER_URL" != "$ORIG_SERVER_URL" ]] || [[ "$SERVER_PORT" != "$ORIG_SERVER_PORT" ]]; then
    echo "Wireguard setup: SERVER_URL and/or SERVER_PORT has changed – updating configs:"

    for i in ${CLIENTS_ARRAY[@]}; do
      CLIENT_NAME=$(setClientName "${i}")

      echo "Wireguard setup: - Updating ${CLIENT_NAME} configs."

      sed -i "/Endpoint /s/=.*$/= ${SERVER_URL}:${SERVER_PORT}/" /config/${CLIENT_NAME}/${CLIENT_NAME}.conf
    done
  else
    echo "Wireguard setup: No changes to SERVER_URL and/or SERVER_PORT – existing configs will be used."
  fi
}

# ------------------------------------------------------------------------------
# Test to see if "$CLIENT_DNS" has changed, if so update and update configs.
# ------------------------------------------------------------------------------
testClientDNS () {
  if [[ "$CLIENT_DNS" != "$ORIG_CLIENT_DNS" ]]; then
    echo "Wireguard setup: CLIENT_DNS has changed – updating configs:"
    
    for i in ${CLIENTS_ARRAY[@]}; do
      CLIENT_NAME=$(setClientName "${i}")

      echo "Wireguard setup: - Updating ${CLIENT_NAME} configs."

      sed -i "/DNS /s/=.*$/= ${CLIENT_DNS}/" /config/${CLIENT_NAME}/${CLIENT_NAME}.conf
    done
  else
    echo "Wireguard setup: No changes to CLIENT_DNS – existing configs will be used."
  fi
}

# ------------------------------------------------------------------------------
# Test to see if "$ALLOWED_IPS" has changed, if so update and update configs.
# ------------------------------------------------------------------------------
testAllowedIPs () {
  if [[ "$ALLOWED_IPS" != "$ORIG_ALLOWED_IPS" ]]; then
    echo "Wireguard setup: ALLOWED_IPS has changed – updating configs:"

    for i in ${CLIENTS_ARRAY[@]}; do
      CLIENT_NAME=$(setClientName "${i}")

      echo "Wireguard setup: - Updating ${CLIENT_NAME} configs."

      sed -i "/AllowedIPs /s/=.*$/= ${ALLOWED_IPS}/" /config/${CLIENT_NAME}/${CLIENT_NAME}.conf
    done    
  else
    echo "Wireguard setup: No changes to ALLOWED_IPS – existing configs will be used."
  fi
}


# ------------------------------------------------------------------------------
# Actual script starts here.
# ------------------------------------------------------------------------------
preFolderAndSymlink
prepTemplates

# ------------------------------------------------------------------------------
# Checks to see if CLIENTS has been set and if so initialise some variables.
# ------------------------------------------------------------------------------
if [[ -n "$CLIENTS" ]]; then
  getClientsArray

  setServerURL

  SERVER_PORT=${SERVER_PORT:-51820}
  echo "Wireguard setup: External server port set to ${SERVER_PORT}/udp. Make sure this is forwarded to 51820/udp inside this container."

  INTERNAL_SUBNET=${INTERNAL_SUBNET:-10.10.0.0}
  echo "Wireguard setup: The internal subnet is set to ${INTERNAL_SUBNET}."

  INTERFACE=$(echo "$INTERNAL_SUBNET" | awk 'BEGIN{FS=OFS="."} NF--')

  ALLOWED_IPS=${ALLOWED_IPS:-0.0.0.0/0}
  echo "Wireguard setup: The allowed IPs for clients ares ${ALLOWED_IPS}."

  setClientDNS
fi

# ------------------------------------------------------------------------------
# Checks for presense of of CLIENTS and server config file:
# 
# - If there are clients and no server config, generate all configs.
# - If there are clients and a server config, check for changes.
# - If there are no clients or server config, assume client mode and tell user to 
#   create one.
# - If there are no clients and a server config, assume client mode.
# ------------------------------------------------------------------------------
if [[ -n "$CLIENTS" ]] && [[ ! -f /config/wg0.conf ]]; then
  echo "Wireguard setup: Server mode selected."

  generateServerConf
  generateClientConfs

  saveDockerEnvVariables
elif [[ -n "$CLIENTS" ]] && [[ -f /config/wg0.conf ]]; then
  echo "Wireguard setup: Server mode already selected. Checking for changes…"

  [[ -f /config/.dont-touch-this-do-do-do-do ]] && \
    . /config/.dont-touch-this-do-do-do-do

  testClientsOrInterface
  testServerURLOrPort
  testClientDNS
  testAllowedIPs
  
  saveDockerEnvVariables
elif [[ -f /config/wg0.conf ]]; then
  echo "Wireguard setup: Client mode selected. Create a client config file at /config/wg0.conf and restart the container."
else
  echo "Wireguard setup: Client mode selected."
fi

# ------------------------------------------------------------------------------
# Set correct permissions for the config folder to avoid permission errors.
# ------------------------------------------------------------------------------
echo "Wireguard setup: Chowning /config to ${PUID} with group ${PGID}"
chown -R ${PUID}:${PGID} /config
