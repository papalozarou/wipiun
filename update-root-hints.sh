#!/bin/bash

# -----------------------------------------------------------------------------
# Script to be run periodically, as required. The best way is to set up a cron
# job to run this script every 6-9 months.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Variable for docker.
# -----------------------------------------------------------------------------
DOCKER="/usr/bin/docker"

# -----------------------------------------------------------------------------
# Run simple apline linux container and download latest root.hints.
# -----------------------------------------------------------------------------
$DOCKER run --rm -v services_unbound_conf:/etc/unbound --workdir /etc/unbound alpine:latest wget -S https://www.internic.net/domain/named.cache -O root.hints