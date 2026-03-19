# Base the local image on the upstream Bitcoin Core image.
ARG BITCOIN_CORE_TAG=latest
FROM ruimarinho/bitcoin-core:${BITCOIN_CORE_TAG}

# Document the ports used by regtest RPC and P2P.
# `EXPOSE` is metadata only; publishing still happens in `docker run -p ...`.
EXPOSE 18443 18444
