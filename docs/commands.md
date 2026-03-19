# Command reference

This document provides a human-friendly reference for the local Bitcoin Core `regtest` commands exposed through the project `Makefile`.

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
