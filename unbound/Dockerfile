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
LABEL description="An experimental Dockerised Unbound, built on Alpine Linux."
LABEL website="https://github.com/$IMG_PFX/wipiun"

# -----------------------------------------------------------------------------
# Variables for use during build, set either here or via `.env` and 
# `docker-compose` files. 
# -----------------------------------------------------------------------------
ARG C_USR
ARG C_GRP
ARG C_USR_DIR

# -----------------------------------------------------------------------------
# Copy "entrypoint.sh" to user directory.
#
# N.B.
# This is done first as the user directory already exists in the base image, and
# we can add the "chmod" part to the below "RUN" command.
# -----------------------------------------------------------------------------
COPY --chown=$C_USR:$C_GRP ./scripts/ $C_USR_DIR/

# -----------------------------------------------------------------------------
# Update and install "perl" and "unbound", then make "entrypoint.sh" executable.
# -----------------------------------------------------------------------------
RUN apk update && \
    apk add --no-cache perl \
        unbound && \
    chmod +x $C_USR_DIR/entrypoint.sh

# -----------------------------------------------------------------------------
# Expose ports for unbound (53/tcp and 53/udp). Both TCP and UDP are specified 
# for verbosity.
# -----------------------------------------------------------------------------
EXPOSE 53/tcp
EXPOSE 53/udp

# ------------------------------------------------------------------------------
# Set user and working directory, run "entrypoint.sh", then run Unbound 
# on startup, via "exec "$@""" in "entrypoint.sh`.
# ------------------------------------------------------------------------------
USER $C_USR
WORKDIR $C_USR_DIR

ENTRYPOINT ["./entrypoint.sh"]