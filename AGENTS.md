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
| **State Management** | BLoC (`flutter_bloc`) with hand-written immutable states/events |
| **Architecture** | Packages-first Flutter workspace monorepo; feature-first app shell + layered module internals |
| **Bitcoin node** | Bitcoin Core 24.0.1, `regtest`, Docker, RPC on `127.0.0.1:18443` |
| **Key storage** | `flutter_secure_storage` |
| **Bitcoin libraries** | `crypto 3.0.7` + `pointycastle 4.0.0` — manual BIP39/32/84/86, all address types |

---

## Project Structure

```
bitcoin_wallet/
├── lib/                         # Flutter app (presentation)
│   ├── core/                    # constants/, routing/
│   ├── common/                  # widgets/, extensions/, utils/
│   └── feature/<feature>/       # Feature-first modules
│       ├── bloc/                # BLoC + feature-specific mappers
│       ├── di/                  # Scoped DI (InheritedWidget + BlocFactory)
│       └── view/                # screen/, widget/
├── packages/
│   ├── address/                 # Address bounded context
│   ├── bitcoin_node/            # Bitcoin Core adapter implementations
│   ├── keys/                    # Mnemonic, seed, derivation, crypto
│   ├── rpc_client/              # Bitcoin Core JSON-RPC HTTP client
│   ├── shared_kernel/           # Tiny shared primitives and contracts
│   ├── storage/                 # flutter_secure_storage adapter
│   ├── transaction/             # Transaction + UTXO bounded context
│   ├── ui_kit/                  # Design system — tokens, typography, theme
│   └── wallet/                  # Wallet bounded context
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
│   ├── BW-000N/                 # Branch workspace (cleaned before merge into master)
│       ├── .active_ticket       # Current ticket ID
│       ├── idea-TICKET.md       # Problem + user stories + acceptance criteria
│       ├── vision-TICKET.md     # Full technical design
│       ├── tasklist-TICKET.md   # Master phase checklist
│       ├── TICKET-phase-N-summary.md
│       ├── phase/TICKET/        # Session briefs (Implementer reads)
│       ├── plan/                # Implementation plans (exact files, code, steps)
│       ├── prd/                 # Formal requirements (QA + Reviewer baseline)
│       ├── research/            # Per-phase research notes
│       ├── qa/                  # QA records (PS/NE/MC/IV scenarios + verdict)
│       └── security/            # Critical-lane security reviews
├── .claude/
│   ├── settings.json            # Claude-native runtime hooks and guardrails
│   ├── agents/                  # Project subagents
│   ├── skills/                  # Project slash commands and domain skills
│   ├── hooks/                   # Command hook entrypoints
│   └── bin/                     # Validator backend
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
IDEA_READY → PRD_READY → RESEARCH_DONE → VISION_APPROVED → PLAN_APPROVED
→ TASKLIST_READY → IMPLEMENT_STEP_OK → REVIEW_OK
→ SECURITY_REVIEW_OK (Critical only) → QA_PASS
→ RELEASE_READY → DOCS_UPDATED
```

Default lane: `Professional`
Mandatory `Critical` lane: wallet, seed, keys, auth, crypto, signing, storage migration, API contracts

**Claude-native runtime**:

- `.claude/settings.json` — committed hook layer
- `.claude/agents/` — project subagents
- `.claude/skills/` — slash commands and domain skills
- `CLAUDE.md` — project memory and default rules

**Agents** (`.claude/agents/`):

| Agent | Reads | Writes |
|-------|-------|--------|
| `analyst` | `idea-TICKET.md` | `prd/TICKET-phase-N.prd.md` |
| `researcher` | `idea.md` + `prd/` + `lib/` | `vision-TICKET.md` + `research/TICKET-phase-N.md` |
| `planner` | `vision.md` + `prd/` + `research/` | `plan/TICKET-phase-N.md` + `phase/TICKET/phase-N.md` |
| `implementer` | `phase/TICKET/phase-N.md` + `plan/` | code + tasklist `[x]` |
| `reviewer` | diff + plan + prd | `TICKET-phase-N-summary.md` |
| `security-reviewer` | diff + plan + prd + review summary | `security/TICKET-phase-N.md` |
| `qa` | prd + phase/ + plan/ | `qa/TICKET-phase-N.md` |

**Skills** (`.claude/skills/`):

| Skill | Usage |
|-------|-------|
| `/aidd-new-ticket BW-0002` | Scaffold idea/tasklist stubs + set `.active_ticket` |
| `/aidd-new-phase 3` | Scaffold stubs in phase/, plan/, prd/, research/ |
| `/aidd-start-phase 3` | Load context, propose first batch |
| `/aidd-complete-phase 3` | Verify checklist + run checks + route to review flow |
| `/aidd-run-checks` | MCP-first format + analyze + test |
| `/aidd-validate` | Validate workflow assets, metadata headers, stale references |
| `/aidd-ship-feature` | Release readiness + docs sync + cleanup checklist |
| `/aidd-init` | Bootstrap AIDD v3 structure for new project or upgrade |

**Hooks and guards**:

- Claude hooks in `.claude/settings.json` are the primary guardrail layer
- `PostToolUse` auto-formats `.dart` files after Write/Edit
- validator is required

**Team mode** (off by default):

- Enable: `export AIDD_TEAM_MODE=1`
- Use for 3+ phases or cleanly separable workstreams
- Orchestrator stays in main context; teammates get disjoint workstreams
- See [docs/project/workflow.md](docs/project/workflow.md) for details

---

## Code Guidelines

Full rules in [docs/project/conventions.md](docs/project/conventions.md) and [docs/project/code-style-guide.md](docs/project/code-style-guide.md). Key rules:

### Architecture
- Clean Architecture + Hexagonal: app presentation → package application/domain ← adapter packages
- Workspace monorepo: one app first, reusable code in `packages/`
- Feature-first in app: `lib/feature/<feature>/` — BLoC + DI + View only
- `packages/` is the canonical top-level name for workspace packages — never `components/`
- Manual constructor-based DI — no GetIt, no service locator
- Scope widgets with `InheritedWidget` for feature-scoped DI
- Two wallet types coexist: Node Wallet (custodial, RPC) + HD Wallet (non-custodial, BIP39)

### BLoC
- BLoC only — no Cubits
- Events: past-tense nouns (`WalletLoaded`, `BalanceFetched`)
- State: hand-written immutable state classes with explicit status enums
- All mutable state in State class — no private BLoC fields (except `StreamSubscription`)
- `abstract interface class` for interfaces, `Impl` suffix for implementations

### Code style
- No `!` operator — extract to local variable, null-check, use promoted type
- No `dynamic` — use `Object` or `Object?`; JSON maps are `Map<String, Object?>`
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

1. Read `docs/<TICKET>/.active_ticket` — identify current ticket
2. Read `docs/<TICKET>/phase/<TICKET>/phase-N.md` — session brief
3. Read `docs/<TICKET>/plan/<TICKET>-phase-N.md` and `docs/<TICKET>/prd/<TICKET>-phase-N.prd.md`
4. Read `docs/project/conventions.md` — architecture rules
5. Check the lane and required gates for the current phase
6. Propose the next batch, wait for explicit OK

## After Making Changes

1. Run `/aidd-run-checks`
2. Mark completed tasks `[x]` in phase brief and `tasklist-<TICKET>.md`
3. Show diff, explain what changed and why
4. Stop on a meaningful boundary before the next batch
