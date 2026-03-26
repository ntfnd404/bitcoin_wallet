---
name: flutter-bitcoin-rpc-integration
description: Plan or implement Flutter app integration with the local Bitcoin Core regtest node. Use when adding RPC calls to the Flutter app, defining data models, or mapping Bitcoin Core responses to app state. Keeps app-rpc-contract.md in sync.
compatibility: Requires Flutter SDK and a running bitcoin-wallet-regtest node
allowed-tools: Read Grep Glob
---

# Flutter Bitcoin RPC Integration

## Sources of truth

1. `docs/app-rpc-contract.md`
2. `docs/phases/phase-04-app-integration.md`
3. `docs/phases/progress.md`
4. `lib/main.dart`

## Rules

- Do not change Docker or Makefile workflows unless the app architecture explicitly requires it.
- Keep the app contract aligned with RPC methods already used in the `Makefile`.
- Document any newly required RPC methods in `docs/app-rpc-contract.md`.
- The node is always `127.0.0.1:18443`, credentials `bitcoin/bitcoin`, wallet `demo`.

## Integration priorities

Build in this order:

1. Node status — `getblockchaininfo`, `getblockcount`
2. Wallet loaded state — `getwalletinfo`, `listwallets`
3. Balances — `getbalances`, `getbalance`
4. Address generation — `getnewaddress`
5. Transaction list — `listtransactions`, `gettransaction`
6. UTXO list — `listunspent`, `gettxout`

## App-facing models

| Model | Fields (map only what UI needs) |
|---|---|
| `NodeStatus` | chain, blockHeight, synced |
| `WalletBalances` | confirmed, unconfirmed, immature |
| `ReceiveAddress` | address, type |
| `WalletTransaction` | txid, amount, confirmations, direction, timestamp |
| `UtxoEntry` | txid, vout, amount, address, confirmations |
| `RpcError` | code, message |

## Required error handling

| Case | RPC trigger |
|---|---|
| Node unavailable | Connection refused / timeout |
| Wallet not loaded | `-rpcwallet` endpoint returns error |
| Wallet missing | Need `loadwallet` or `createwallet` |
| Invalid address | `sendtoaddress` rejects format |
| Insufficient balance | `sendtoaddress` returns insufficient funds |
| Unknown TXID | `gettransaction` / `getrawtransaction` not found |
| Spent UTXO | `gettxout` returns null |

## When proposing or implementing a change

State explicitly:
1. RPC method used
2. App model affected
3. UI flow affected
4. Docs that must stay in sync
