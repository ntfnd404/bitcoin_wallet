---
name: bitcoin-regtest-operator
description: Operational work on the local Bitcoin Core regtest node. Use for node lifecycle, wallet readiness, Docker state inspection, and diagnosing failures. Covers make btc-up, btc-build, btc-wallet-ready, btc-mine, btc-status, and cleanup targets.
compatibility: Requires Docker and make
allowed-tools: Read Grep Glob Bash
---

# Bitcoin Regtest Operator

## Sources of truth

Read in order:
1. `AGENTS.md`
2. `README.md`
3. `Makefile` — single source of truth for all infrastructure constants and commands

For failure patterns, see [references/diagnostics.md](references/diagnostics.md).

## Rules

- Always prefer `make` targets. Do not use raw `docker run` or `docker exec` unless explicitly asked.
- The project image is `bitcoin-wallet-regtest:<BITCOIN_CORE_VERSION>` — not the upstream `ruimarinho/bitcoin-core` image.
- `btc-up` builds the image only if it is missing. Use `btc-build` to force a rebuild.
- Treat `bitcoin-wallet-regtest-data` as the persisted chain and wallet state.

## First pass checklist

1. `docker/bitcoin.conf` exists
2. `docker/Dockerfile` exists
3. `bitcoin-wallet-regtest-data` volume exists (if node has been started before)
4. If node needs to be running: `make btc-up` → `make btc-wallet-ready` → `make btc-status`

## Standard flows

### Bring the node up

```sh
make btc-up            # builds image if missing, starts container
make btc-wallet-ready  # loads or creates demo wallet
make btc-status        # confirms chain is live
```

### Fund the demo wallet

```sh
make btc-wallet-ready
make btc-mine          # mines 101 blocks; coinbase becomes spendable
make btc-balances
```

### Rebuild after config change

```sh
make btc-build         # forces rebuild with fresh OCI labels
make btc-restart       # stops old container, starts fresh one
```

### Diagnose broken environment

See [references/diagnostics.md](references/diagnostics.md) for the full failure table. Quick order:
1. `make btc-logs` — container lifecycle
2. `make btc-status` — RPC reachability
3. `make btc-wallets`, `make btc-wallet-info` — wallet state
4. `make btc-blockcount` — chain height
5. `make btc-docker-state` — volume presence

## Status report format

Always include:
- Node running: yes / no
- Wallet loaded: yes / no
- Block height: N
- Confirmed balance: X BTC (or "no funds")
- Volume `bitcoin-wallet-regtest-data`: present / missing
