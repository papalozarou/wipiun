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

# -----------------------------------------------------------------------------
# Variables for use during build, set either here or via `.env` and 
# `docker-compose` files. 
# -----------------------------------------------------------------------------
ARG C_UID
ARG C_GID
ARG C_USR
ARG C_GRP
ARG C_WGD_PORT

# -----------------------------------------------------------------------------
# Copy "entrypoint.sh" and config files.
#
# N.B.
# This is done first as the user directory already exists in the base image, and
# we can add the "chmod" part to the below "RUN" command.
# -----------------------------------------------------------------------------
COPY --chown=$C_USR:$C_GRP ./scripts/ $C_USR_DIR/
COPY --chown=$C_USR:$C_GRP ./defaults $C_USR_DIR/defaults

# -----------------------------------------------------------------------------
# Update and install "libqrencode" and "wireguard-tools", then make 
# "entrypoint.sh" executable.
# -----------------------------------------------------------------------------
RUN apk update && \
    apk add libqrencode \
        wireguard-tools && \
    chmod +x $C_USR_DIR/entrypoint.sh

# -----------------------------------------------------------------------------
# Expose port for Wireguard, UDP is set for verbosity.
# -----------------------------------------------------------------------------
EXPOSE $C_WGD_PORT/udp

# ------------------------------------------------------------------------------
# Set user and working directory, run "entrypoint.sh", then run Wireguard 
# on startup, via "exec "$@""" in "entrypoint.sh`.
# ------------------------------------------------------------------------------
USER $C_USR
WORKDIR $C_USR_DIR

ENTRYPOINT ["./entrypoint.sh" ]


