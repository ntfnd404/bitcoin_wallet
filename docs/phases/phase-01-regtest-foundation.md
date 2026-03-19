# Phase 01: Regtest foundation

Status: `completed`

## Goal

Set up a local Bitcoin Core environment that is reproducible, isolated, and easy to operate through project commands.

## What is already done

1. Added a project Docker image based on `ruimarinho/bitcoin-core`.
2. Added `docker/bitcoin.conf` for local `regtest` configuration.
3. Added `Makefile` commands for build, run, logs, RPC, wallet, and UTXO operations.
4. Added local persistent storage in `.docker/bitcoin`.
5. Added README instructions for startup, reset, and troubleshooting.

## Exit criteria

- Local node starts with `make bitcoin-up`.
- Wallet can be prepared with `make bitcoin-wallet-ready`.
- Wallet can be funded with `make bitcoin-mine`.
- Local state can be reset with `make bitcoin-reset-data`.
