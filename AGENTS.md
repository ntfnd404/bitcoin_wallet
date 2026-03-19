# Repository guide for agents

This repository contains a Flutter wallet project and a local Bitcoin Core `regtest` environment for development, RPC training, and wallet experiments.

## Primary workflow

- Prefer the `Makefile` as the main interface for local Bitcoin Core operations.
- Prefer `regtest` for all local development and demo scenarios.
- Prefer project docs in `docs/` before making assumptions about goals or current phase.

## Key files

- `Makefile` is the primary entry point for node lifecycle, wallet, transaction, and UTXO commands.
- `docker/Dockerfile` defines the local Bitcoin Core image.
- `docker/bitcoin.conf` defines the active node configuration.
- `docs/learning-goals.md` defines the learning objectives.
- `docs/rpc-learning-path.md` defines the practical RPC training route.
- `docs/phases/README.md` and `docs/phases/progress.md` describe current and planned phases.

## Operational rules

- Do not replace `Makefile` workflows with raw `docker run` or `docker exec` commands unless explicitly requested.
- Do not introduce `docker-compose` unless the project grows beyond a single Bitcoin Core service.
- Do not duplicate node configuration between `docker/bitcoin.conf` and container runtime flags without a strong reason.
- Keep RPC exposure local-first; prefer `127.0.0.1` bindings for local development.
- Treat `.docker/bitcoin` as the local persisted chain state for `regtest`.

## Documentation rules

- Keep the root `README.md` concise and oriented toward project entry, quick start, and command discovery.
- Put longer training, planning, and phase-tracking material in `docs/`.
- Update `docs/phases/progress.md` when a learning or implementation phase meaningfully changes.

## Change strategy

- Make focused changes that preserve the current `regtest` workflow.
- Prefer extending existing `Makefile` targets over adding parallel scripts or duplicate entry points.
- When adding new RPC-oriented capabilities, document them in the relevant `docs/` files if they affect learning flow or project phases.
