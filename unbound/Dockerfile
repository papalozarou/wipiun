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

# ------------------------------------------------------------------------------
# Copy "entrypoint.sh" script to "/""
# ------------------------------------------------------------------------------
COPY ./entrypoint.sh /entrypoint.sh

# ------------------------------------------------------------------------------
# Set execute permissions on the script.
# ------------------------------------------------------------------------------
RUN chmod +x /entrypoint.sh && \
# ------------------------------------------------------------------------------
# Install perl – for "entrypoint.sh" – tini and unbound.
# ------------------------------------------------------------------------------
    apk update && \
    apk add --no-cache perl \
        tini \
        unbound

# ------------------------------------------------------------------------------
# Expose ports for unbound (53/tcp and 53/udp). Both TCP and UDP are specified 
# for verbosity.
# ------------------------------------------------------------------------------
EXPOSE 53/tcp
EXPOSE 53/udp

# ------------------------------------------------------------------------------
# Run unbound, via "entrypoint.sh" script on startup.
# ------------------------------------------------------------------------------
CMD ["/entrypoint.sh"]