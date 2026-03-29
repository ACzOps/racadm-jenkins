# RACADM client for Dell PowerEdge R420 (iDRAC7)
# Built from Dell iDRAC Tools RPMs on Debian Bookworm slim
#
# iDRAC Tools archive:
#   https://dl.dell.com/FOLDER13988164M/1/Dell-iDRACTools-Web-LX-11.4.0.0-1435_A00.tar.gz
#   All versions: https://www.dell.com/support/product-details/en-us/product/idrac-tools/drivers
#
# Build:  docker build --build-arg IDRAC_TARBALL="Dell-iDRACTools-Web-LX-11.4.0.0-1435_A00.tar.gz" -t racadm:latest .
# Usage:  docker compose run --rm racadm getsysinfo

FROM debian:trixie-slim AS builder

ARG IDRAC_TARBALL

RUN apt-get update && apt-get install -y --no-install-recommends \
      alien \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/idrac

COPY ${IDRAC_TARBALL} idrac-tools.tar.gz

RUN tar xzf idrac-tools.tar.gz \
    && cd iDRACTools/racadm/RHEL8/x86_64 \
    && alien --to-deb *.rpm \
    && dpkg -i *.deb

FROM debian:trixie-slim

RUN apt-get update && apt-get install -y \
      libssl3 \
      libc6 \
      openjdk-25-jdk
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/dell /opt/dell

RUN ln -sf /usr/lib/x86_64-linux-gnu/libssl.so.3 /usr/lib/x86_64-linux-gnu/libssl.so \
    && ln -sf /opt/dell/srvadmin/bin/idracadm7 /usr/local/bin/racadm
