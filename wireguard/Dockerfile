# ------------------------------------------------------------------------------
# Set image prefix and Alpine version for base image.
# ------------------------------------------------------------------------------
ARG IMG_PFX
ARG ALP_VER

# ------------------------------------------------------------------------------
# Base image and metadata.
# ------------------------------------------------------------------------------
FROM $IMG_PFX/alpine-base-$ALP_VER:latest

LABEL maintainer="Papa Lozarou"
LABEL description="An experimental Dockerised Wireguard, built on Alpine Linux."
LABEL website="https://github.com/$IMG_PFX/wipiun"

# ------------------------------------------------------------------------------
# Update and install "libqrencode" and "wireguard-tools", then make 
# "entrypoint.sh" executable.
# ------------------------------------------------------------------------------
RUN apk update && \
    apk add libqrencode \
        s6-overlay \
        wireguard-tools
    
# -----------------------------------------------------------------------------
# Copy "root" folder "/".
# -----------------------------------------------------------------------------
COPY ./root /

RUN chmod +x /etc/s6-overlay/scripts/*.sh

# -----------------------------------------------------------------------------
# Expose port for wireguard (51820/udp) and run wireguard via s6 init.
# -----------------------------------------------------------------------------
EXPOSE 51820/udp

ENTRYPOINT ["/init"]