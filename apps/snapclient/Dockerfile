# Tiny snapclient image built on Debian Trixie.
# We build locally (rather than pulling a community image) so the version of
# snapclient is pinned to whatever Trixie ships and matches the system's ALSA
# stack exactly.
FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends snapclient ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# `audio` group exists in the base image; member of the `audio` GID can open
# /dev/snd nodes when they're bind-mounted from the host.
ENTRYPOINT ["/usr/bin/snapclient"]
