# Progress tracker

This document tracks what has already been completed, what is currently in progress, and what should be studied next.

## Current status

- Phase 01: `completed`
- Phase 02: `in progress`
- Phase 03: `planned`
- Phase 04: `planned`

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
- [x] Add reusable Claude Code commands in `.claude/commands/`.

### Phase 02: RPC wallet basics

- [x] Start and stop the local node through `make`.
- [x] Load or create a demo wallet.
- [x] Inspect node state with blockchain and network RPC calls.
- [x] Inspect wallet state with wallet RPC calls.
- [x] Generate addresses for `legacy`, `p2sh-segwit`, `bech32`, and `bech32m`.
- [ ] Practice reading balances after mining and sending funds.
- [ ] Write down the RPC calls that matter most for the app layer.

### Phase 03: Transactions and UTXO

- [ ] Send funds between local addresses.
- [ ] Inspect wallet transaction history.
- [ ] Decode transactions by TXID.
- [ ] Inspect mempool state before and after confirmation.
- [ ] Compare `listunspent` with `gettxout`.
- [ ] Trace how a send changes spendable outputs.

### Phase 04: App integration

- [ ] Define how the Flutter app will call Bitcoin RPC.
- [ ] Define wallet models for addresses, balances, transactions, and UTXOs.
- [ ] Connect local node data to the app.
- [ ] Add repeatable local scenarios for app testing.

## Next recommended step

Work through Phase 02 until wallet state, balances, and address types feel mechanical.
Then move to Phase 03 and trace one send transaction end to end.
