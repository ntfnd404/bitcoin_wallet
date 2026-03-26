# AGENTS.md

Repository guide for agents and contributors. Full project reference.

For Claude Code quick-start, see [CLAUDE.md](CLAUDE.md).

---

## Project Overview

A Flutter wallet app paired with a local Bitcoin Core `regtest` node running in Docker.
Demonstrates Bitcoin engineering: HD wallets, BIP39/32/84/86, all address types, UTXO model, coin selection, Bitcoin Script.

**Two wallet types:**
- **Node Wallet** (custodial) — Bitcoin Core manages keys; Flutter is a UI over RPC
- **HD Wallet** (non-custodial) — BIP39 mnemonic in app; keys in flutter_secure_storage

---

## Technical Context

| Field | Value |
|-------|-------|
| **Language** | Dart 3 / Flutter |
| **State Management** | BLoC (`flutter_bloc`) with `freezed` for immutable states/events |
| **Architecture** | Clean Architecture (Presentation → Domain → Data), feature-first modules |
| **Bitcoin node** | Bitcoin Core 24.0.1, `regtest`, Docker, RPC on `127.0.0.1:18443` |
| **Key storage** | `flutter_secure_storage` |
| **Bitcoin libraries** | `coinlib` — HD wallets, BIP39/32/84/86, all address types, Taproot |

---

## Project Structure

```
bitcoin_wallet/
├── lib/                         # Flutter app source
│   └── feature/<feature>/       # Feature-first modules
│       ├── bloc/                # BLoC state management
│       ├── di/                  # Scoped DI (Scope widget + BlocFactory)
│       ├── domain/              # Feature-specific business logic
│       └── view/                # Screens and widgets
├── docker/
│   ├── Dockerfile               # Thin project image on pinned upstream
│   └── bitcoin.conf             # Tracked node config (baked into image)
├── docs/
│   ├── project/                 # Persistent docs (stays in master)
│   │   ├── conventions.md       # Architecture + code rules — the constitution
│   │   ├── workflow.md          # AIDD process, agent roles, quality gates
│   │   ├── guidelines.md        # Flutter/Dart AI guidelines
│   │   ├── code-style-guide.md  # Dart formatting and naming conventions
│   │   ├── adr/                 # Architecture Decision Records
│   │   ├── templates/           # Abstract AIDD document templates
│   │   ├── phases/              # Project-level roadmap (8 phases + progress)
│   │   ├── app-rpc-contract.md  # Planned contract between app and Bitcoin Core RPC
│   │   ├── learning-goals.md    # Learning objectives for this project
│   │   └── rpc-learning-path.md # Structured Bitcoin RPC learning path
│   └── feature/                 # Branch workspace (cleaned before merge into master)
│       ├── .active_ticket       # Current ticket ID
│       ├── idea-TICKET.md       # Problem + user stories + acceptance criteria
│       ├── vision-TICKET.md     # Full technical design
│       ├── tasklist-TICKET.md   # Master phase checklist
│       ├── TICKET-phase-N-summary.md
│       ├── phase/TICKET/        # Session briefs (Implementer reads)
│       ├── plan/                # Implementation plans (exact files, code, steps)
│       ├── prd/                 # Formal requirements (QA + Reviewer baseline)
│       ├── research/            # Per-phase research notes
│       └── qa/                  # QA records (PS/NE/MC/IV scenarios + verdict)
├── Makefile                     # Single source of truth for all infra commands
├── CLAUDE.md                    # Claude Code project instructions (concise)
└── AGENTS.md                    # This file — full reference for agents
```

---

## Build and Infrastructure Commands

`make help` shows the full grouped command list. Key workflows:

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

---

## Flutter Commands

```sh
flutter analyze          # Static analysis — must be clean before marking task done
dart format lib/ test/   # Format source files
flutter test             # Run all tests
```

---

## AIDD Workflow

See [docs/project/workflow.md](docs/project/workflow.md) for the full process. Summary:

```
IDEA_READY → PRD_READY → RESEARCH_DONE → PLAN_APPROVED → TASKLIST_READY
→ (per phase) IMPLEMENT_STEP_OK → REVIEW_OK → QA_PASS
→ RELEASE_READY → DOCS_UPDATED
```

**Agents** (`.claude/agents/`):

| Agent | Reads | Writes |
|-------|-------|--------|
| `analyst` | `idea-TICKET.md` | `prd/TICKET-phase-N.prd.md` |
| `researcher` | `idea.md` + `prd/` + `lib/` | `vision-TICKET.md` + `research/TICKET-phase-N.md` |
| `planner` | `vision.md` + `prd/` + `research/` | `plan/TICKET-phase-N.md` + `phase/TICKET/phase-N.md` |
| `implementer` | `phase/TICKET/phase-N.md` + `plan/` | code + tasklist `[x]` |
| `reviewer` | diff + plan + prd | `TICKET-phase-N-summary.md` |
| `qa` | prd + phase/ + plan/ | `qa/TICKET-phase-N.md` |

**Skills** (`.claude/skills/`):

| Skill | Usage |
|-------|-------|
| `/new-ticket FEAT-002` | Scaffold idea stub + set `.active_ticket` |
| `/new-phase 3` | Scaffold stubs in phase/, plan/, prd/, research/ |
| `/start-phase 3` | Load context, propose first task |
| `/complete-phase 3` | Verify checklist + run checks |
| `/run-checks` | `dart format` + `flutter analyze` + `flutter test` |
| `/ship-feature` | CHANGELOG entry + cleanup checklist |

---

## Code Guidelines

Full rules in [docs/project/conventions.md](docs/project/conventions.md) and [docs/project/code-style-guide.md](docs/project/code-style-guide.md). Key rules:

### Architecture
- Clean Architecture: Presentation → Domain → Data
- Feature-first: `lib/feature/<feature>/`
- Manual constructor-based DI — no GetIt, no service locator
- Scope widgets with `InheritedWidget` for feature-scoped DI

### BLoC
- BLoC only — no Cubits
- Events: past-tense nouns (`WalletLoaded`, `BalanceFetched`)
- State: single `@freezed` class with `enum` status — not multiple factory constructors
- All mutable state in State class — no private BLoC fields (except `StreamSubscription`)
- `abstract interface class` for interfaces, `Impl` suffix for implementations

### Code style
- No `!` operator — extract to local variable, null-check, use promoted type
- No `print` — use `dart:developer` log
- No magic numbers — named constants
- Always curly braces in control flow

### Bitcoin-specific
- Address prefixes in regtest: Legacy=`m`, P2SH=`2`, Bech32=`bcrt1q`, Bech32m=`bcrt1p`
- Seed phrase: never in logs, never in SharedPreferences
- Private keys: never in UI layer or logs
- HD derivation must be deterministic: same seed → same addresses on re-import

---

## Operational Rules

- Use `make` targets — do not replace with raw `docker run` or `docker exec` unless explicitly asked
- All infrastructure constants live in `Makefile` — there is no `constants.mk`
- To upgrade Bitcoin Core: update `BITCOIN_CORE_VERSION` and the `sha256:` digest in `BITCOIN_BASE_IMAGE`:
  ```sh
  docker buildx imagetools inspect ruimarinho/bitcoin-core:<new-version> | grep Digest
  ```
  Use the top-level manifest list digest (first line), not a platform-specific one.
- Keep `docker/bitcoin.conf` as the tracked config source; bake it into the image via `docker/Dockerfile`
- Do not introduce `docker-compose` for a single-service setup
- RPC bindings stay local-first (`127.0.0.1`)

---

## Before Making Changes

1. Read `docs/feature/.active_ticket` — identify current ticket
2. Read `docs/feature/phase/<TICKET>/phase-N.md` — session brief
3. Read `docs/project/conventions.md` — architecture rules
4. Propose the change, wait for explicit OK

## After Making Changes

1. Run `flutter analyze` — zero warnings required
2. Run `dart format lib/` — format changed files
3. Mark completed tasks `[x]` in phase brief and `tasklist-<TICKET>.md`
4. Show diff, explain what changed and why
5. Stop and wait for confirmation before the next task
