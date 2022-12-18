# -----------------------------------------------------------------------------
# Base image and metadata.
# -----------------------------------------------------------------------------
FROM alpine:latest

LABEL maintainer="Papa Lozarou"
LABEL description="Experimental Wireguard alpine image."

# -----------------------------------------------------------------------------
# Variables for use during build, set either here or via `.env` and 
# `docker-compose` files. 
# -----------------------------------------------------------------------------
ARG UID
ARG GID
ARG USR
ARG GRP

RUN apk update && \
    apk add libqrencode \
        s6-overlay \
        wireguard-tools && \
# -----------------------------------------------------------------------------
# Create group $GRP with $GID, user $USR with $UID.
# -----------------------------------------------------------------------------
    addgroup -g $GID $GRP && \
    adduser -S -u $UID -G $GRP $USR
    
# -----------------------------------------------------------------------------
# Copy `unbound.sh` script to `/`
# -----------------------------------------------------------------------------
COPY ./root /

RUN chmod +x /etc/s6-overlay/scripts/*.sh

# -----------------------------------------------------------------------------
# Expose port for wireguard 51820/udp). 
# -----------------------------------------------------------------------------
EXPOSE 51820/udp

ENTRYPOINT ["/init"]


