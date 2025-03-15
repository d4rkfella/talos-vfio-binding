FROM alpine:3.21.2@sha256:56fa17d2a7e7f168a043a2712e63aed1f8543aeafdcee47c58dcffe38ed51099

RUN apk update && apk add --no-cache \
    bash \
    zfs \
    catatonit

WORKDIR /app

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]

LABEL org.opencontainers.image.source="https://github.com/d4rkfella/talos-vfio-binding"
LABEL org.opencontainers.image.title="talos-vfio-binding"
LABEL org.opencontainers.image.authors="Georgi Panov"
