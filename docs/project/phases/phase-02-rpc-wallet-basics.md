# Phase 02: RPC wallet basics

Status: `current`

## Goal

Build confidence with Bitcoin Core RPC and understand the wallet surface before deeper transaction analysis.

## Focus areas

1. Read node state with `getblockchaininfo`, `getblockcount`, and `getnetworkinfo`.
2. Inspect wallet state with `getwalletinfo`, `getbalances`, and `listwallets`.
3. Generate addresses across the supported address types.
4. Understand the difference between wallet balance and wallet UTXO state.

## Recommended commands

1. `make btc-status`
2. `make btc-blockcount`
3. `make btc-network-info`
4. `make btc-wallet-info`
5. `make btc-wallets`
6. `make btc-address-legacy`
7. `make btc-address-p2sh-segwit`
8. `make btc-address-bech32`
9. `make btc-address-taproot`
10. `make btc-balances`

## Exit criteria

- You can explain what the node, wallet, and address RPC calls return.
- You can generate each supported address type on demand.
- You can read wallet balances and loaded wallet state without guessing.
