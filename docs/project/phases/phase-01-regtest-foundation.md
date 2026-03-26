# Phase 01: Regtest foundation

Status: `completed`

## Goal

Set up a local Bitcoin Core environment that is reproducible, isolated, and easy to operate through project commands.

## What is already done

1. Added a local `regtest` startup flow based on `ruimarinho/bitcoin-core`.
2. Added a thin project image in `docker/Dockerfile` built on a pinned upstream base (tag + SHA256 digest for full reproducibility).
3. Added `docker/bitcoin.conf` for local `regtest` configuration baked into that image.
4. Added `.dockerignore` to limit the Docker build context to `docker/bitcoin.conf` only.
5. Added `Makefile` as the single source of truth for all infrastructure constants (`BITCOIN_CORE_VERSION`, base image, project image tag, ports, volume name) and all operational commands.
6. Added OCI image labels (`title`, `description`, `created`, `revision`) stamped at build time.
7. Added named Docker volume storage for local persistent `regtest` state.
8. Added README and `docs/` instructions for startup, upgrade, reset, and troubleshooting.

## Exit criteria

- Local node starts with `make btc-up`.
- Wallet can be prepared with `make btc-wallet-ready`.
- Wallet can be funded with `make btc-mine`.
- Local state can be reset with `make btc-reset-data`.
