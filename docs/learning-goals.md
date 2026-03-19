# Learning goals

This document describes the main learning goals for the local Bitcoin wallet and Bitcoin Core `regtest` environment.

## Core goals

1. Understand how a local Bitcoin Core node works in `regtest`.
2. Learn how to communicate with the node through RPC.
3. Understand wallet lifecycle: create, load, inspect, and fund.
4. Understand address types: `legacy`, `p2sh-segwit`, `bech32`, and `bech32m`.
5. Learn how transactions affect balances, mempool state, and UTXOs.
6. Learn how to inspect chain data and specific outputs with RPC.

## Practical goals

1. Start and stop the local node without manual Docker commands.
2. Reset local `regtest` state when the chain becomes noisy or inconsistent.
3. Fund the wallet on demand by mining local blocks.
4. Generate addresses for different script types.
5. Send transactions and inspect them through wallet and chain RPC calls.
6. Read and reason about UTXO state for a wallet.

## Application goals

1. Use the local node as a reproducible backend for wallet experiments.
2. Build confidence before integrating wallet logic into the Flutter app.
3. Keep the environment deterministic and independent from public `testnet`.
