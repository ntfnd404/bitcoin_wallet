# Progress tracker

This document tracks what has already been completed, what is currently in progress, and what is planned.

Checklist items are closed when the Flutter app implements the feature, not when a `make` command is run.
`make` commands are exploration tools — use them to understand the RPC surface before building the app layer.

## Ticket map

| Ticket | Phases | Status |
|--------|--------|--------|
| BW-0001 | 01, 02, 03 | closed |
| BW-0002 | 04, 05 | closed |
| BW-0003 | 06 | in progress |

## Current status

- Phase 01: `completed` — BW-0001
- Phase 02: `completed` — BW-0001
- Phase 03: `completed` — BW-0001
- Phase 04: `completed` — BW-0002
- Phase 05: `completed` — BW-0002
- Phase 06: `in progress` — BW-0003
- Phase 07: `planned`
- Phase 08: `planned`

## Checklist

### Phase 01: Regtest foundation

- [x] Add a thin Docker image for the local Bitcoin Core startup flow.
- [x] Pin upstream base image by tag and SHA256 digest for full reproducibility.
- [x] Add OCI image labels (title, description, created, revision) stamped at build time.
- [x] Add `.dockerignore` to reduce build context to `docker/bitcoin.conf` only.
- [x] Add `regtest` configuration in `docker/bitcoin.conf`.
- [x] Consolidate all infrastructure constants into `Makefile` as single source of truth.
- [x] Add `Makefile` commands for node lifecycle, wallet, transaction, and UTXO workflows.
- [x] Move persistent local state to the named Docker volume `bitcoin-wallet-regtest-data`.
- [x] Add project documentation for startup, upgrade, reset, and troubleshooting.

### Phase 02: Node connectivity and wallet state

Flutter app reads basic node and wallet state via RPC.

- [x] RPC client layer implemented in Flutter (HTTP JSON-RPC calls to Bitcoin Core).
- [x] App displays node connectivity status (reachable / unreachable).
- [x] App displays current block height and chain name.
- [x] App displays wallet loaded state (`getwalletinfo`).
- [x] App displays confirmed, unconfirmed, and immature balances separately (`getbalances`).

### Phase 03: Address management

Flutter app generates and displays Bitcoin addresses.

- [x] App generates a legacy (P2PKH) address via RPC.
- [x] App generates a P2SH-SegWit address via RPC.
- [x] App generates a native SegWit bech32 (P2WPKH) address via RPC.
- [x] App generates a Taproot (P2TR) address via RPC.
- [x] Address displayed as copyable text.
- [ ] Address displayed as QR code.
- [ ] Address labeled as used or unused based on transaction history.

### Phase 04: Transaction history and UTXO inspection

Flutter app displays transaction history and raw UTXO state.

- [x] App displays wallet transaction list with direction, amount, and confirmations.
- [x] App displays transaction detail: all inputs, all outputs, fee, size in bytes, weight.
- [x] App displays raw transaction hex.
- [x] App distinguishes mempool (unconfirmed) transactions from confirmed ones.
- [x] App displays UTXO list with TXID, vout, amount, confirmations, address, and script type.
- [x] App displays individual UTXO detail including raw output script and derivation path.

### Phase 05: Send transaction and coin selection strategies

Flutter app constructs, signs, and broadcasts transactions with user-controlled coin selection.

- [x] App sends a transaction with destination address and amount input.
- [x] App shows transaction summary (inputs, outputs, fee, change) before broadcast.
- [x] App implements FIFO coin selection strategy (oldest UTXOs first).
- [x] App implements LIFO coin selection strategy (newest UTXOs first).
- [x] App implements minimize-inputs strategy (fewest UTXOs to cover amount).
- [x] App implements minimize-change strategy (closest match to minimize change output).
- [x] App compares strategies side by side: estimated fee, input count, change amount.
- [ ] App allows manual UTXO selection for a transaction.
- [x] App broadcasts raw transaction via `sendrawtransaction`.
- [x] App displays TXID after successful broadcast.
- [x] App exposes "Mine block" action (`generatetoaddress`) to confirm pending transactions.

### Phase 06: Key derivation and self-signing

Flutter app derives keys from a BIP39 seed phrase and signs transactions internally.

- [x] App generates a BIP39 mnemonic (12 or 24 words).
- [x] App derives keys following BIP84/86/44/49 for regtest.
- [x] App generates receiving addresses from the derived key tree.
- [x] App imports an existing BIP39 mnemonic and restores the same addresses.
- [x] App displays the derived xpub and derivation path.
- [x] App signs transactions internally (private keys in memory; no `signrawtransactionwithwallet`).
- [ ] Signed transactions verified by broadcasting to regtest and confirming via `getrawtransaction`.

### Phase 07: Bitcoin Script

Flutter app constructs scripts, broadcasts script-bearing transactions, and decodes scripts.

- [ ] App constructs and broadcasts a transaction with an `OP_RETURN` output.
- [ ] App decodes and displays the locking script for any output.
- [ ] App decodes and displays the unlocking script for any input.
- [ ] App labels script types: P2PKH, P2SH, P2WPKH, P2WSH, P2TR, OP_RETURN, UNKNOWN.

### Phase 08: Polish and demo

- [ ] App builds and runs on iOS.
- [ ] App builds and runs on Android.
- [ ] App builds and runs on macOS.
- [ ] App builds and runs on web.
- [ ] Architecture documented (layers: data, domain, presentation).
- [ ] README includes one-command demo setup (`make btc-up` → launch app → ready).
- [ ] All core user stories completable end-to-end without errors.
