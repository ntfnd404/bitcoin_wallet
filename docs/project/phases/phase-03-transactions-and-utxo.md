# Phase 03: Transactions and UTXO

Status: `planned`

## Goal

Understand how wallet actions create transactions, how those transactions appear in wallet history, and how they change the UTXO set.

## Focus areas

1. Send funds and observe transaction creation.
2. Inspect wallet transactions by TXID.
3. Decode raw transactions from the chain or mempool.
4. Inspect wallet UTXOs with `listunspent`.
5. Inspect specific outputs with `gettxout`.
6. Compare confirmed and unconfirmed transaction states.

## Recommended commands

1. `make btc-send ADDRESS=<bcrt-address> AMOUNT=0.5`
2. `make btc-transactions`
3. `make btc-transaction TXID=<txid>`
4. `make btc-raw-transaction TXID=<txid>`
5. `make btc-mempool`
6. `make btc-utxos`
7. `make btc-utxo TXID=<txid> VOUT=0`

## Exit criteria

- You can trace a wallet transaction from send to UTXO impact.
- You can explain the difference between wallet transaction history and chain transaction data.
- You can identify whether a given output is still unspent.
