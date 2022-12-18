# -----------------------------------------------------------------------------
# Base image and metadata.
# -----------------------------------------------------------------------------
FROM alpine:latest

LABEL maintainer="Papa Lozarou"
LABEL description="Experimental Unbound alpine image."

# -----------------------------------------------------------------------------
# Variables for use during build, set either here or via `.env` and 
# `docker-compose` files. 
# -----------------------------------------------------------------------------
ARG UID
ARG GID
ARG USR
ARG GRP

# -----------------------------------------------------------------------------
# Copy `unbound.sh` script to `/`
# -----------------------------------------------------------------------------
COPY ./unbound.sh /unbound.sh

# -----------------------------------------------------------------------------
# Set execute permissions on the script.
# -----------------------------------------------------------------------------
RUN chmod +x /unbound.sh && \
# -----------------------------------------------------------------------------
# Install perl – for `unbound.sh` – tini and unbound.
# -----------------------------------------------------------------------------
    apk update && \
    apk add --no-cache perl \
        tini \
        unbound && \
# -----------------------------------------------------------------------------
# Create group $GRP with $GID, user $USR with $UID.
# -----------------------------------------------------------------------------
    addgroup -g $GID $GRP && \
    adduser -S -u $UID -G $GRP $USR

# -----------------------------------------------------------------------------
# Expose ports for unbound (53/tcp and 53/udp). Both TCP and UDP are specified 
# for verbosity.
# -----------------------------------------------------------------------------
EXPOSE 53/tcp
EXPOSE 53/udp

# -----------------------------------------------------------------------------
# Run unbound, via `unbound.sh` script on startup.
# -----------------------------------------------------------------------------
CMD ["/unbound.sh"]



    