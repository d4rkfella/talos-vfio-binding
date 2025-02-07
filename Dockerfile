FROM ubuntu:24.04

RUN apt-get update && apt-get install -y 
    zfsutils-linux \
    catatonit

WORKDIR /app

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]

LABEL org.opencontainers.image.source="https://github.com/d4rkfella/talos-vfio-binding"
LABEL org.opencontainers.image.title="talos-vfio-binding"
LABEL org.opencontainers.image.authors="Georgi Panov"
