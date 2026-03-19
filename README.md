# bitcoin_wallet

Demo Bitcoin wallet project with a local Bitcoin Core `regtest` node for development and testing.

## Overview

This project combines a Flutter wallet app with a local Bitcoin Core node running in `regtest` mode.
The local node is intended for development, wallet experiments, and reproducible demos without relying on public `testnet` infrastructure.

- `docker/Dockerfile` defines the local Bitcoin Core image.
- `docker/bitcoin.conf` defines the node configuration for `regtest`.
- `Makefile` provides local commands for building, running, funding wallets, and inspecting UTXOs.

## Quick start

1. Install and start Docker.
2. Clone the repository and open the project root.
3. Run `make bitcoin-up` to build the local image and start the local Bitcoin Core node.
4. Run `make bitcoin-wallet-ready` to load the demo wallet or create it if missing.
5. Run `make bitcoin-mine` to mine 101 blocks and fund the wallet.
6. Run `make bitcoin-balance` or `make bitcoin-utxos` to inspect wallet funds.

## Demo workflow

Typical local flow:

1. Start the node with `make bitcoin-up`.
2. Prepare the wallet with `make bitcoin-wallet-ready`.
3. Mine blocks with `make bitcoin-mine`.
4. Inspect wallet state with `make bitcoin-balance` and `make bitcoin-utxos`.
5. Create specific address types with `make bitcoin-address-legacy`, `make bitcoin-address-bech32`, or `make bitcoin-address-taproot`.
6. Send funds with `make bitcoin-send ADDRESS=<bcrt-address> AMOUNT=0.5`.
7. Inspect a specific output with `make bitcoin-utxo TXID=<txid> VOUT=0`.

## Commands and docs

- Run `make help` for the full list of commands (also see `Makefile`).
- See `docs/README.md` for the documentation index and workflow notes.

## Notes

- The node runs in `regtest`, not `mainnet` and not `testnet`.
- Chain data is stored in `.docker/bitcoin`, so it survives container recreation.
- The first startup needs network access to pull the upstream `ruimarinho/bitcoin-core` image.

## Troubleshooting

- If Docker commands fail, make sure Docker Desktop or the Docker daemon is running.
- If the first `make bitcoin-up` is slow, Docker may still be pulling `ruimarinho/bitcoin-core`.
- If a wallet command fails after restart, run `make bitcoin-wallet-ready` to load or recreate the wallet.
- If you want a clean `regtest` chain, run `make bitcoin-reset-data`.
