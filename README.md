# bitcoin_wallet

Demo Bitcoin wallet project with a local Bitcoin Core `regtest` node for development and testing.

## Overview

This project combines a Flutter wallet app with a local Bitcoin Core node running in `regtest` mode.
The local node is intended for development, wallet experiments, and reproducible demos without relying on public `testnet` infrastructure.

- `docker/bitcoin.conf` defines the tracked node configuration for `regtest`.
- `docker/Dockerfile` defines the thin project image built on top of a pinned upstream Bitcoin Core base image (tag + SHA256 digest).
- `Makefile` is the single source of truth for all infrastructure constants and provides commands for node lifecycle, wallet, transaction, and UTXO operations.
- The project-managed Docker container is named `bitcoin-wallet-regtest`.
- The container runs from the project image `bitcoin-wallet-regtest:<version>`, uses baked-in config from `docker/bitcoin.conf`, and stores chain state in the named volume `bitcoin-wallet-regtest-data`.

## Quick start

1. Install and start Docker.
2. Clone the repository and open the project root.
3. Run `make btc-up` to build the thin project image if needed and start the local Bitcoin Core node.
4. Run `make btc-wallet-ready` to load the demo wallet or create it if missing.
5. Run `make btc-mine` to mine 101 blocks and fund the wallet.
6. Run `make btc-balance` or `make btc-utxos` to inspect wallet funds.

## App configuration

The app reads Bitcoin RPC settings from Dart defines. The tracked local
development config lives in `config/dev.env`.

- VS Code launch configs already pass `--dart-define-from-file=config/dev.env`.
- Run from CLI with `flutter run --dart-define-from-file=config/dev.env`.
- Run tests with `flutter test --dart-define-from-file=config/test.env`.
- If you start the app without the define file, startup fails fast with a
  configuration error.

## Demo workflow

Typical local flow:

1. Start the node with `make btc-up`.
2. Prepare the wallet with `make btc-wallet-ready`.
3. Mine blocks with `make btc-mine`.
4. Inspect wallet state with `make btc-balance` and `make btc-utxos`.
5. Create specific address types with `make btc-address-legacy`, `make btc-address-bech32`, or `make btc-address-taproot`.
6. Send funds with `make btc-send ADDRESS=<bcrt-address> AMOUNT=0.5`.
7. Inspect a specific output with `make btc-utxo TXID=<txid> VOUT=0`.

## Commands and docs

- Run `make help` for the full list of commands (also see `Makefile`).
- See `docs/README.md` for the documentation index and workflow notes.
- Use `make btc-docker-state` to inspect only this project's Bitcoin Docker artifacts.
- Use `make btc-clean-runtime` to remove the container and runtime state while keeping the project image.
- Use `make btc-clean-all` for a full cold start cleanup, including the project image and versioned upstream base cache.

## Notes

- The node runs in `regtest`, not `mainnet` and not `testnet`.
- Chain data is stored in the named Docker volume `bitcoin-wallet-regtest-data`, so it survives container recreation.
- The tracked config from `docker/bitcoin.conf` is baked into the project image at build time.
- The upstream base image is pinned by both tag and SHA256 digest for full reproducibility. To upgrade Bitcoin Core, update `BITCOIN_CORE_VERSION` and the digest in `Makefile`:
  ```sh
  docker buildx imagetools inspect ruimarinho/bitcoin-core:<new-version> | grep Digest
  ```
- The first startup needs network access to pull the upstream base image and build the project image.

## Troubleshooting

- If Docker commands fail, make sure Docker Desktop or the Docker daemon is running.
- If the first `make btc-up` is slow, Docker may still be fetching the versioned upstream base image before building the project image.
- If a wallet command fails after restart, run `make btc-wallet-ready` to load or recreate the wallet.
- If you want a clean `regtest` chain, run `make btc-reset-data`.
