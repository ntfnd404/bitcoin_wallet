# Idea: Transaction History + UTXO Inspection (BW-0002)

Status: `IDEA_READY`
Ticket: BW-0002
Phase: feature
Lane: Professional
Workflow Version: 3
Owner: Product / Architect
Date: 2026-04-18
Depends On: []
Blocked Until: none

---

## Problem

The wallet app can now generate addresses and derive keys from a BIP39 seed, but developers using it cannot see what actually happened on the blockchain. There is no visibility into:

- Which transactions belong to the wallet
- Which UTXOs are available for spending
- The actual direction (incoming/outgoing) and confirmation status of a transaction
- The raw structure of a transaction (inputs, outputs, scripts)

Without this visibility, a developer cannot develop the mental model of the Bitcoin UTXO model or make informed decisions about coin selection strategies (Phase 05). This feature is foundational to understanding Bitcoin.

---

## Business Goal

Build full transaction history and UTXO inspection capability in the app, allowing the developer to see exactly what Bitcoin Core reports about the wallet's on-chain activity. This is prerequisite for sending transactions and coin selection strategies.

---

## Scope

- [x] App lists wallet transactions with txid, direction, amount, confirmations, timestamp
- [x] App displays transaction detail: all inputs, all outputs, fee, size in bytes, weight, raw hex
- [x] App lists wallet UTXOs with txid, vout, amount, confirmations, address, script type
- [x] App displays UTXO detail: raw output script, derivation path
- [x] App distinguishes mempool (unconfirmed) transactions from confirmed ones
- [x] New domain package: `packages/transaction/` with Transaction, Utxo entities and repositories
- [x] New RPC adapter: `TransactionRemoteDataSourceImpl` in `packages/bitcoin_node/`
- [x] New BLoCs and screens: `TransactionBloc`, `UtxoBloc`, navigation from `WalletDetailScreen`

### Non-goals

- Sending transactions (Phase 05)
- Script construction or custom Script scenarios (Phase 07)
- Fee estimation beyond simple per-transaction display (Phase 05)
- Address labeling (used/unused) — Phase 03 remainder
- QR code display — Phase 03 remainder

---

## User Stories

- As a developer, I want to see my wallet's transaction history so that I understand what Bitcoin Core knows about my addresses.
- As a developer, I want to see the detail of each transaction (inputs, outputs, scripts) so that I can understand transaction structure and serialization.
- As a developer, I want to see my UTXOs individually so that I understand why Bitcoin has no "balance" at the protocol level — only unspent outputs.
- As a developer, I want to know which UTXOs are confirmed vs mempool so that I can understand confirmation risk.
- As a developer, I want to inspect the raw output script of each UTXO so that I can learn script types (P2PKH, P2SH, P2WPKH, P2WSH, P2TR).

---

## Dependencies

- Phase 06 items already done: BIP39, key derivation, address generation, key import
- RPC client (packages/rpc_client/): already exists; will add new RPC methods
- Bitcoin Core regtest node: must be running for all features
- No other product phases block this one

---

## Acceptance Criteria

| Criterion | Verification |
|-----------|--------------|
| Transaction list displays for a wallet with history | Create wallet, generate address, receive coins (via `sendtoaddress` from regtest node), observe list in app |
| Transaction detail shows all inputs and outputs | Tap a transaction → see inputs (txid, vout) and outputs (address, amount, script) |
| UTXO list shows available outputs | Tap wallet → see UTXO list with amount, confirmations |
| Mempool vs confirmed are visually distinguished | Create tx, observe in app as unconfirmed; mine block via Makefile; observe confirmation |
| Raw transaction hex is displayable | User can copy/inspect raw hex of any transaction |
| All code is DDD-layered and testable | Entities in domain/, logic in application/, RPC in data/; unit tests for domain entities |
| No `package:domain/` or `package:data/` imports remain | Grep clean; only new module packages used |
| Dart analyzer and DCM pass | `flutter analyze --fatal-infos` and `dcm analyze` clean |

---

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| RPC methods return different field formats in different regtest versions | Low | Pin Bitcoin Core version in docker/bitcoin.conf; document assumptions |
| Mempool timeout causes missed unconfirmed tx in UI | Medium | Poll `listtransactions` with mempool=true every N seconds; do not cache |
| Raw script decoding is complex for all script types | Medium | Start with P2PKH, P2WPKH, P2TR; label unknown scripts; do not attempt full decoder in Phase 04 |
| UTXO stale if not refreshed after send | Medium | Refresh UTXO list after send (in Phase 05 send-flow); or poll on screen focus |

---

## Open Questions

- [ ] How often should transaction list refresh? (on demand, or polling with interval?)
- [ ] Should transaction detail include full scriptPubKey decoded, or raw hex only?
- [ ] How many transactions and UTXOs will a typical Phase 06 wallet have? (affects pagination/virtualization need)
- [ ] Should derivation path be displayed for each UTXO, or only in detail view?
