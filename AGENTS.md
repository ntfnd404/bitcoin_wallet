# Repository guide for agents

This repository contains a Flutter wallet project and a local Bitcoin Core `regtest` environment for development, RPC training, and wallet experiments.

## Primary workflow

- Prefer the `Makefile` as the main interface for local Bitcoin Core operations.
- Prefer `regtest` for all local development and demo scenarios.
- Prefer project docs in `docs/` before making assumptions about goals or current phase.

## Key files

- `Makefile` is the primary entry point and the single source of truth for all infrastructure constants (`BITCOIN_CORE_VERSION`, `BITCOIN_BASE_IMAGE`, `BITCOIN_IMAGE`, ports, volume name).
- `docker/Dockerfile` defines the thin project image built on a pinned upstream Bitcoin Core base (tag + SHA256 digest).
- `docker/bitcoin.conf` defines the tracked Bitcoin Core configuration baked into that image.
- `.dockerignore` limits the Docker build context to `docker/bitcoin.conf` only.
- `docs/learning-goals.md` defines the learning objectives.
- `docs/rpc-learning-path.md` defines the practical RPC training route.
- `docs/phases/README.md` and `docs/phases/progress.md` describe current and planned phases.
- `.claude/skills/` contains reusable skills: `bitcoin-regtest-operator`, `bitcoin-rpc-learning`, `flutter-bitcoin-rpc-integration`, `bitcoin-core-upgrade`, `regtest-scenario`, `prd-writing`.

## Operational rules

- Do not replace `Makefile` workflows with raw `docker run` or `docker exec` commands unless explicitly requested.
- Do not introduce `docker-compose` unless the project grows beyond a single Bitcoin Core service.
- All infrastructure constants live in `Makefile` — there is no `constants.mk`.
- Keep `docker/bitcoin.conf` as the tracked source config and bake it into the project image through `docker/Dockerfile`.
- Keep RPC exposure local-first; prefer `127.0.0.1` bindings for local development.
- Treat the named Docker volume `bitcoin-wallet-regtest-data` as the persisted chain state for `regtest`.
- To upgrade Bitcoin Core: update `BITCOIN_CORE_VERSION` and the `sha256:` digest in `Makefile`. Get the new digest with `docker buildx imagetools inspect ruimarinho/bitcoin-core:<version> | grep Digest`.

## Documentation rules

- Keep the root `README.md` concise and oriented toward project entry, quick start, and command discovery.
- Put longer training, planning, and phase-tracking material in `docs/`.
- Update `docs/phases/progress.md` when a learning or implementation phase meaningfully changes.

## Change strategy

- Make focused changes that preserve the current `regtest` workflow.
- Prefer extending existing `Makefile` targets over adding parallel scripts or duplicate entry points.
- When adding new RPC-oriented capabilities, document them in the relevant `docs/` files if they affect learning flow or project phases.
