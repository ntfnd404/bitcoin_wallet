# syntax=docker/dockerfile:1

# BITCOIN_BASE_IMAGE must be supplied at build time — no default intentionally.
# The Makefile is the single source of truth for the upstream image version.
ARG BITCOIN_BASE_IMAGE

FROM ${BITCOIN_BASE_IMAGE}

# Bake the tracked regtest config into the image so no runtime volume mount is needed.
COPY docker/bitcoin.conf /etc/bitcoin/bitcoin.conf

# OCI image labels — populated at build time by btc-build.
# Placed after COPY so the COPY layer can be reused from cache on metadata-only rebuilds.
ARG BUILD_DATE
ARG GIT_REVISION
LABEL org.opencontainers.image.title="bitcoin-wallet-regtest" \
      org.opencontainers.image.description="Bitcoin Core regtest node for local wallet development" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${GIT_REVISION}"

EXPOSE 18443 18444

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD bitcoin-cli -conf=/etc/bitcoin/bitcoin.conf -regtest getblockchaininfo >/dev/null 2>&1 || exit 1

CMD ["-conf=/etc/bitcoin/bitcoin.conf"]
