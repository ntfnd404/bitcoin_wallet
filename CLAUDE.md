# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Key documents (read before working)

- **[docs/project/conventions.md](./docs/project/conventions.md)** — architecture, wallet types, code rules. The constitution. Always follow.
- **[docs/project/workflow.md](./docs/project/workflow.md)** — AIDD process: phase lifecycle, agent roles, skill commands, quality gates.
- **[docs/project/guidelines.md](./docs/project/guidelines.md)** — Flutter/Dart AI interaction guidelines.
- **[docs/project/code-style-guide.md](./docs/project/code-style-guide.md)** — Dart formatting and naming conventions.

## Working on a feature

Feature branches are named `BW-000N-<description>` (e.g. `BW-0001-wallet-creation`).
Each feature has its own workspace folder `docs/BW-000N/` — **not merged to master**.

Before any code changes:
1. Read `docs/<TICKET>/.active_ticket` — confirm the current ticket ID (e.g. `BW-0001`).
2. Read `docs/<TICKET>/phase/<TICKET>/phase-N.md` — session brief (tasks + context).
3. Read `docs/<TICKET>/plan/<TICKET>-phase-N.md` — implementation details.
4. Read `docs/<TICKET>/prd/<TICKET>-phase-N.prd.md` — acceptance criteria.
5. Propose the change plan and wait for explicit OK.

After code changes:
1. Run `flutter analyze` — zero warnings required before marking any task done.
2. Run `dart format lib/` on changed files.
3. Mark completed tasks `[x]` in `docs/<TICKET>/phase/<TICKET>/phase-N.md` and `docs/<TICKET>/tasklist-<TICKET>.md`.
4. Show diff and explain what changed.
5. Stop and wait for confirmation before the next task.

## Project overview

A Flutter wallet app paired with a local Bitcoin Core `regtest` node running in Docker.
Demonstrates Bitcoin engineering: HD wallets, BIP39/32/84/86, all address types, UTXO model, coin selection, Bitcoin Script.

Two wallet types:
- **Node Wallet** (custodial) — Bitcoin Core manages keys, Flutter is a UI over RPC.
- **HD Wallet** (non-custodial) — BIP39 mnemonic in app, keys in flutter_secure_storage.

## Common commands

Run `make help` for the full grouped command list. Key workflows:

```sh
# Node lifecycle
make btc-up              # Build image if needed and start node
make btc-down            # Stop and remove container
make btc-reset-data      # Wipe persisted chain data volume
make btc-restart         # Recreate container, keep chain data
make btc-logs            # Follow node stdout
make btc-shell           # Open shell in the container

# Wallet and funding
make btc-wallet-ready    # Load wallet or create it if missing
make btc-mine            # Mine 101 blocks (makes coinbase spendable)
make btc-balance         # Show wallet balance
make btc-balances        # Show confirmed/unconfirmed/immature breakdown
make btc-send ADDRESS=bcrt1... AMOUNT=0.5

# Address types
make btc-address-legacy
make btc-address-p2sh-segwit
make btc-address-bech32
make btc-address-taproot

# Transaction and UTXO inspection
make btc-transactions
make btc-transaction TXID=<txid>
make btc-raw-transaction TXID=<txid>
make btc-mempool
make btc-utxos
make btc-utxo TXID=<txid> VOUT=0

# Arbitrary RPC
make btc-cli ARGS="getblockchaininfo"

# Cleanup (in order of increasing destructiveness)
make btc-clean-runtime   # Remove container + data, keep image
make btc-clean-all       # Remove container, data, and images
```

## Architecture

### Docker layer
- `docker/Dockerfile` — thin project image on pinned upstream `ruimarinho/bitcoin-core:24.0.1`; bakes `docker/bitcoin.conf` into the image; stamped with OCI labels (build date, git revision) at build time
- `docker/bitcoin.conf` — tracked node config (`regtest`, RPC credentials `bitcoin/bitcoin`, `txindex=1`, `fallbackfee=0.0002`)
- `.dockerignore` — build context includes only `docker/bitcoin.conf`; excludes Flutter build artifacts
- Named volume `bitcoin-wallet-regtest-data` — persisted chain state; survives container recreation

### Makefile
The `Makefile` is the single source of truth for all infrastructure constants and the only supported operational interface. Key variables at the top: `BITCOIN_CORE_VERSION`, `BITCOIN_BASE_IMAGE`, `BITCOIN_IMAGE` (versioned as `bitcoin-wallet-regtest:<version>`). It defines two CLI aliases:
- `BITCOIN_NODE_CLI` — node-level RPC (no wallet context)
- `BITCOIN_WALLET_CLI` — wallet-level RPC (`-rpcwallet=demo`)

`btc-up` builds the image automatically on first run only; use `btc-build` to force a rebuild after config changes.

RPC is exposed on `127.0.0.1:18443` (RPC) and `127.0.0.1:18444` (P2P).

### Flutter app (`lib/` + `packages/`)
- Clean Architecture + Hexagonal: Presentation → Domain ← Data
- Workspace monorepo: `packages/domain`, `packages/data`, `packages/rpc_client`, `packages/storage`, `packages/ui_kit`
- Feature-first in app: `lib/feature/<feature>/` — BLoC + DI + View only (no domain/ or data/ inside feature)
- Shared app code: `lib/core/` (routing, constants), `lib/common/` (widgets, extensions, utils)
- BLoC state management — no Cubits
- Two wallet types: Node Wallet (custodial, RPC) + HD Wallet (non-custodial, BIP39/BIP32)
- See [docs/project/conventions.md](./docs/project/conventions.md) for full architecture rules

### Project phases
| Phase | Status | Focus |
|-------|--------|-------|
| 01 | completed | Docker + Makefile foundation |
| 02 | in progress | Flutter RPC client, node status, wallet state, balances |
| 03 | planned | Address generation (all types), QR display |
| 04 | planned | Transaction history, UTXO inspection |
| 05 | planned | Send flow, coin selection strategies, manual UTXO |
| 06 | planned | BIP39 seed phrase, BIP84 key derivation, self-signing |
| 07 | planned | Bitcoin Script, OP_RETURN, script decoder |
| 08 | planned | Multi-platform polish, demo setup |

## Commit messages

Follow conventional commits:
- `feat:` — new feature
- `fix:` — bug fix
- `refactor:` — code change without behaviour change
- `chore:` — tooling, config, build, deps
- `docs:` — documentation only
- `test:` — tests only

Format: `type(scope): description` where scope is the feature or module (e.g. `feat(wallet): add BIP84 derivation`).

## Operational rules

- Use `make` targets — do not replace them with raw `docker run` or `docker exec` unless explicitly asked.
- All infrastructure constants live in the `Makefile` variables section — there is no `constants.mk`.
- To upgrade Bitcoin Core: update `BITCOIN_CORE_VERSION` and the `sha256:` digest in `BITCOIN_BASE_IMAGE` in the `Makefile`. Get the new digest with:
  ```sh
  docker buildx imagetools inspect ruimarinho/bitcoin-core:<new-version> | grep Digest
  ```
  Use the top-level manifest list digest (first line), not a platform-specific one.
- Keep `docker/bitcoin.conf` as the tracked config source; bake it into the image via `docker/Dockerfile`.
- Do not introduce `docker-compose` for a single-service setup.
- RPC bindings stay local-first (`127.0.0.1`).

## Documentation layout

Two layers: `docs/project/` (persistent, stays in master) and `docs/BW-000N/` (branch workspace, never merged to master).

### docs/project/ — persistent

| Path | Purpose |
|------|---------|
| `conventions.md` | Architecture and code rules — the constitution |
| `workflow.md` | AIDD process, phase lifecycle, agent roles, quality gates |
| `guidelines.md` | Flutter/Dart AI interaction guidelines |
| `code-style-guide.md` | Dart formatting and naming conventions |
| `adr/` | Architecture Decision Records (cross-feature decisions) |
| `templates/` | Abstract templates for all AIDD document types |
| `phases/` | Project-level roadmap (8 phases + product requirements) |

### docs/BW-000N/ — branch workspace (never merged to master)

Each feature gets its own folder named after the ticket ID (e.g. `docs/BW-0001/`).
Lives only in its feature branch `BW-000N-<description>`.

| Path | Purpose |
|------|---------|
| `.active_ticket` | Current ticket ID (e.g. `BW-0001`) |
| `idea-<TICKET>.md` | Problem statement + user stories + acceptance criteria |
| `vision-<TICKET>.md` | Full technical design (written by researcher) |
| `tasklist-<TICKET>.md` | Master checklist — progress across all phases |
| `<TICKET>-phase-N-summary.md` | Completion summary per phase (root level) |
| `phase/<TICKET>/phase-N.md` | Session brief — Implementer reads this first |
| `plan/<TICKET>-phase-N.md` | Implementation plan — exact files, code, steps |
| `prd/<TICKET>-phase-N.prd.md` | Formal requirements — QA and Reviewer baseline |
| `research/<TICKET>-phase-N.md` | Research notes per phase |
| `qa/<TICKET>-phase-N.md` | QA record with PS/NE/MC/IV scenarios + verdict |

### Agents and skills

| Path | Purpose |
|------|---------|
| `.claude/agents/analyst.md` | `idea.md` → `prd/` |
| `.claude/agents/researcher.md` | `idea.md` + `prd/` → `vision.md` + `research/` |
| `.claude/agents/implementer.md` | `phase/` + `plan/` → code + tasklist `[x]` |
| `.claude/agents/reviewer.md` | diff + plan + prd → `*-summary.md` + verdict |
| `.claude/agents/qa.md` | prd + phase/ → `qa/` record |
| `.claude/skills/new-ticket/` | `/new-ticket BW-0002` — scaffold idea + .active_ticket |
| `.claude/skills/new-phase/` | `/new-phase 3` — scaffold phase/, plan/, prd/, research/ stubs |
| `.claude/skills/start-phase/` | `/start-phase 3` — load context before implementation |
| `.claude/skills/complete-phase/` | `/complete-phase 3` — verify checklist + run checks |
| `.claude/skills/run-checks/` | `/run-checks` — format + analyze + test |
| `.claude/skills/ship-feature/` | `/ship-feature` — CHANGELOG + cleanup checklist |

### Quality gates

```
IDEA_READY → PRD_READY → RESEARCH_DONE → PLAN_APPROVED → TASKLIST_READY
→ (per phase) IMPLEMENT_STEP_OK → REVIEW_OK → QA_PASS
→ RELEASE_READY → DOCS_UPDATED
```
