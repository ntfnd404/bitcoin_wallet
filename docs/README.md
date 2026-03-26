# Documentation

This folder contains learning, planning, and workflow documents for the local Bitcoin Core `regtest` setup.

## Infrastructure standard

- `Makefile` is the only supported operational entry point and the single source of truth for all infrastructure constants (`BITCOIN_CORE_VERSION`, `BITCOIN_BASE_IMAGE`, `BITCOIN_IMAGE`, ports, volume name).
- `docker/Dockerfile` defines the thin project image built on a pinned upstream Bitcoin Core base image (tag + SHA256 digest).
- `docker/bitcoin.conf` is the tracked config source baked into that image at build time.
- `.dockerignore` limits the Docker build context to `docker/bitcoin.conf` only.
- `bitcoin-wallet-regtest-data` is the persisted Docker volume for node and wallet state.

## Documents

- `learning-goals.md` — what to learn from this project and local RPC practice.
- `app-rpc-contract.md` — planned contract between the app layer and Bitcoin Core RPC.
- `rpc-learning-path.md` — practical command-by-command training route.
- `phases/README.md` — indexes the project phases and their statuses.
- `phases/progress.md` — tracks completed, current, and upcoming work as a checklist.

## Skills

Reusable Claude Code skills live in `.claude/skills/`. Invoke with `/skill-name`:

| Skill | When to use |
|---|---|
| `/bitcoin-regtest-operator` | Node lifecycle, diagnostics, wallet readiness |
| `/bitcoin-rpc-learning` | Guided RPC practice following `docs/rpc-learning-path.md` |
| `/flutter-bitcoin-rpc-integration` | App layer planning and implementation |
| `/bitcoin-core-upgrade` | Upgrade Bitcoin Core version (version + digest update) |
| `/regtest-scenario` | Set up a reproducible chain state for testing or demo |
| `/prd-writing` | Write a Product Requirements Document |

## Suggested reading order

1. `learning-goals.md`
2. `rpc-learning-path.md`
3. `app-rpc-contract.md`
4. `phases/README.md`
