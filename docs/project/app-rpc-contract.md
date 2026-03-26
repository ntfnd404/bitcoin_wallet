# App RPC contract

This document is a working contract between the Flutter app layer and the local Bitcoin Core `regtest` node.
It should be updated whenever the app starts depending on new RPC methods, response fields, or error handling rules.

## Purpose

The goal of this contract is to describe:

1. Which RPC calls the app needs.
2. Which inputs the app provides.
3. Which outputs the app consumes.
4. Which errors or edge cases the app must handle.

## Current status

Status: `draft`

The local node and RPC training workflow already exist.
The app integration layer is not implemented yet, so this document defines the initial contract surface.

## Assumptions

- The node runs locally in `regtest`.
- RPC access is available through project-managed configuration.
- The app should not depend on public `testnet` for core development flows.
- The selected wallet is expected to exist or be created during app initialization.

## Proposed app capabilities

### 1. Read node status

Purpose:
Show whether the local node is reachable and synchronized enough for local workflows.

RPC methods:

- `getblockchaininfo`
- `getnetworkinfo`
- `getblockcount`

App inputs:

- None, beyond node connection settings.

App outputs:

- Current chain name
- Current block height
- Verification progress
- Basic connectivity status

### 2. Read wallet state

Purpose:
Display wallet readiness and balances in the app.

RPC methods:

- `getwalletinfo`
- `getbalances`
- `listwallets`

App inputs:

- Wallet name

App outputs:

- Wallet loaded state
- Confirmed balance
- Unconfirmed balance
- Immature balance

### 3. Generate receive addresses

Purpose:
Allow the app to create addresses for different script types.

RPC methods:

- `getnewaddress`

App inputs:

- Wallet name
- Address type: `legacy`, `p2sh-segwit`, `bech32`, or `bech32m`

App outputs:

- Newly generated address
- Address type used for generation

### 4. Send funds

Purpose:
Allow the app to create outgoing wallet transactions.

RPC methods:

- `sendtoaddress`

App inputs:

- Destination address
- Amount
- Wallet name

App outputs:

- TXID of the created transaction

### 5. Show transaction history

Purpose:
Let the app list and inspect wallet transactions.

RPC methods:

- `listtransactions`
- `gettransaction`
- `getrawtransaction`

App inputs:

- Wallet name
- Optional TXID for detailed inspection

App outputs:

- Transaction list
- Detailed wallet transaction data
- Decoded chain transaction data

### 6. Show UTXO state

Purpose:
Let the app inspect spendable outputs and validate output state.

RPC methods:

- `listunspent`
- `gettxout`

App inputs:

- Wallet name
- Optional TXID and VOUT for direct UTXO inspection

App outputs:

- Wallet UTXO list
- Details for a single chain output

## Error cases to handle

- Node is not running.
- Wallet is not loaded.
- Wallet does not exist yet.
- RPC credentials are invalid.
- Requested TXID is unknown.
- Requested UTXO is already spent.
- Address format is invalid.
- Balance is insufficient for the requested send.

## Open questions

- Will the Flutter app call Bitcoin Core RPC directly or through a local backend layer?
- Which RPC response fields should be mapped into app-specific models first?
- Should wallet creation happen automatically in the app or remain an external setup step?
- Which transaction and UTXO views are required in the first UI milestone?

## Next update trigger

Update this document when any of the following happens:

- The app starts calling RPC from code.
- A backend adapter or proxy is introduced.
- A wallet model is added to the Flutter app.
- New RPC methods become part of the supported app flow.
