# Phase 04: App integration

Status: `planned`

## Goal

Connect the Flutter wallet application to the local `regtest` environment in a controlled and testable way.

## Focus areas

1. Decide how the app will communicate with Bitcoin Core RPC.
2. Define the wallet flows needed in the UI.
3. Map RPC responses to application models.
4. Add local test scenarios for balances, addresses, transactions, and UTXOs.

## Exit criteria

- The app can read wallet state from the local node.
- The app can generate addresses and display balances.
- The app can display transaction and UTXO data from the local environment.
