---
name: bitcoin-core-upgrade
description: Upgrade the Bitcoin Core version in this project. Use when updating BITCOIN_CORE_VERSION in the Makefile, getting the new SHA256 manifest digest, rebuilding the project image, and verifying the upgrade. See references/upgrade-checklist.md to track progress.
compatibility: Requires Docker with buildx and make
allowed-tools: Read Bash
---

# Bitcoin Core Upgrade

## Before you start

Read `Makefile` to confirm current `BITCOIN_CORE_VERSION` and `BITCOIN_BASE_IMAGE` values.
Open [references/upgrade-checklist.md](references/upgrade-checklist.md) to track each step.

## Step 1 — Get the new manifest list digest

```sh
docker buildx imagetools inspect ruimarinho/bitcoin-core:<new-version> | grep Digest
```

Use the **first** `Digest:` line — that is the multi-arch manifest list digest.
Do NOT use platform-specific digests listed under `Manifests:`.

## Step 2 — Update Makefile

```makefile
BITCOIN_CORE_VERSION ?= <new-version>
BITCOIN_BASE_IMAGE   ?= ruimarinho/bitcoin-core:<new-version>@sha256:<new-digest>
```

`BITCOIN_IMAGE` becomes `bitcoin-wallet-regtest:<new-version>` automatically.

## Step 3 — Rebuild

```sh
make btc-build
```

## Step 4 — Restart and verify

```sh
make btc-restart
make btc-wallet-ready
make btc-status        # confirm chain=regtest, blocks=N
```

## Step 5 — Verify OCI labels

```sh
docker inspect bitcoin-wallet-regtest:<new-version> | grep -A5 Labels
```

Confirm `org.opencontainers.image.revision` and `org.opencontainers.image.created` are present.

## Step 6 — Update docs

Add a note to `docs/phases/progress.md`:
```
- [x] Upgraded Bitcoin Core to <new-version> (<date>)
```

## Rollback

Revert `BITCOIN_CORE_VERSION` and `sha256:` in `Makefile`, then `make btc-build && make btc-restart`.
If chain data is incompatible: `make btc-reset-data` before restarting.
