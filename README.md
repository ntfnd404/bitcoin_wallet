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

## Useful commands

- `make help` prints all available commands grouped by purpose.
- `make bitcoin-up` starts the local Bitcoin Core `regtest` node.
- `make bitcoin-down` stops and removes the current container.
- `make bitcoin-reset-data` removes the local persisted `regtest` chain data.
- `make bitcoin-status` shows chain status and sync information.
- `make bitcoin-blockcount` shows the current block height.
- `make bitcoin-network-info` shows node network information.
- `make bitcoin-wallets` lists loaded wallets.
- `make bitcoin-wallet-ready` loads or creates the selected wallet.
- `make bitcoin-wallet-info` shows detailed wallet RPC information.
- `make bitcoin-balances` shows confirmed, unconfirmed, and immature balances.
- `make bitcoin-address ADDRESS_TYPE=bech32` creates a wallet address of the selected type.
- `make bitcoin-address-legacy` creates a legacy address.
- `make bitcoin-address-p2sh-segwit` creates a wrapped segwit address.
- `make bitcoin-address-bech32` creates a native segwit address.
- `make bitcoin-address-taproot` creates a taproot address.
- `make bitcoin-balance` shows the wallet balance.
- `make bitcoin-mine` mines 101 blocks so coinbase funds become spendable.
- `make bitcoin-transactions` lists recent wallet transactions.
- `make bitcoin-transaction TXID=<txid>` shows one wallet transaction.
- `make bitcoin-raw-transaction TXID=<txid>` decodes a raw chain transaction.
- `make bitcoin-mempool` shows the current mempool.
- `make bitcoin-utxos` lists wallet UTXOs with `listunspent`.
- `make bitcoin-utxo TXID=<txid> VOUT=0` inspects one on-chain UTXO.
- `make bitcoin-cli ARGS="getblockchaininfo"` runs a raw `bitcoin-cli` RPC command.

## Learning docs

- `docs/README.md` is the documentation index.
- `docs/learning-goals.md` defines the learning objectives.
- `docs/rpc-learning-path.md` contains the RPC training route.
- `docs/phases/README.md` tracks completed, current, and planned phases.

## Notes

- The node runs in `regtest`, not `mainnet` and not `testnet`.
- Chain data is stored in `.docker/bitcoin`, so it survives container recreation.
- The first startup needs network access to pull the upstream `ruimarinho/bitcoin-core` image.

## Troubleshooting

- If Docker commands fail, make sure Docker Desktop or the Docker daemon is running.
- If the first `make bitcoin-up` is slow, Docker may still be pulling `ruimarinho/bitcoin-core`.
- If a wallet command fails after restart, run `make bitcoin-wallet-ready` to load or recreate the wallet.
- If you want a clean `regtest` chain, run `make bitcoin-reset-data`.
