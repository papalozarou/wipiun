#!/bin/sh

# ------------------------------------------------------------------------------
# Script to set up Wireguard on container first run.
#
# N.B.
# Wireguard kernal module is assumed to be active on the host machine. If it is 
# not you must install it. It is present on most modern linux installs.
# ------------------------------------------------------------------------------

****** REMEMBER WE'RE USING sh not bash and that it's PUID and GUID ******