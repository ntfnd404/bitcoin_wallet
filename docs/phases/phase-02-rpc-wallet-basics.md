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

1. `make bitcoin-status`
2. `make bitcoin-blockcount`
3. `make bitcoin-network-info`
4. `make bitcoin-wallet-info`
5. `make bitcoin-wallets`
6. `make bitcoin-address-legacy`
7. `make bitcoin-address-p2sh-segwit`
8. `make bitcoin-address-bech32`
9. `make bitcoin-address-taproot`
10. `make bitcoin-balances`

## Exit criteria

- You can explain what the node, wallet, and address RPC calls return.
- You can generate each supported address type on demand.
- You can read wallet balances and loaded wallet state without guessing.
