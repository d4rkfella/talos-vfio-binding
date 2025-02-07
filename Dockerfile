FROM alpine:3.21.2

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
