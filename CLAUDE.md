# CLAUDE.md

## Key Documents

- **[docs/project/conventions.md](./docs/project/conventions.md)** — architecture and package rules
- **[docs/project/code-style-guide.md](./docs/project/code-style-guide.md)** — formatting, naming, import rules
- **[docs/project/workflow.md](./docs/project/workflow.md)** — Claude-Native Enterprise AIDD v3
- **[docs/project/guidelines.md](./docs/project/guidelines.md)** — Flutter/Dart guidance

---

## Project Overview

Flutter wallet app + Bitcoin Core `regtest` node in Docker.

- **Node Wallet** — custodial, Bitcoin Core owns keys
- **HD Wallet** — non-custodial, app owns mnemonic and derivation

Workspace packages: `domain`, `data`, `rpc_client`, `storage`, `ui_kit`.

---

## Runtime Defaults

- Workflow version: `3`
- Runtime model: `Claude-native`
- Default lane: `Professional`
- Mandatory `Critical` lane for wallet, seed, keys, auth, crypto, signing, storage migration, or API contract work

Runtime sources of truth:

- `.claude/settings.json`
- `.claude/agents/`
- `.claude/skills/`
- `CLAUDE.md`

---

## First Session Checks

Run these in Claude Code when starting or debugging the environment:

- `/config`
- `/agents`
- `/hooks`
- `/mcp`
- `claude --version`

## Before Code Changes

1. Read `docs/<TICKET>/.active_ticket`
2. Read `docs/<TICKET>/phase/<TICKET>/phase-N.md`
3. Read `docs/<TICKET>/plan/<TICKET>-phase-N.md`
4. Read `docs/<TICKET>/prd/<TICKET>-phase-N.prd.md`
5. Check lane and gate requirements in the current phase
6. Propose the next batch and wait for explicit approval

---

## After Code Changes

1. Run `/aidd-run-checks`
2. Run the phase checks required by the lane
3. Update `phase/<TICKET>/phase-N.md` and `tasklist-<TICKET>.md`
4. Show the diff and explain the completed batch
5. Stop on a meaningful boundary

---

## Documentation Layout

- `docs/project/` — persistent source of truth
- `docs/BW-000N/` — branch-local feature workspace, never merged

Core commands:

- `/aidd-new-ticket`
- `/aidd-new-phase`
- `/aidd-start-phase`
- `/aidd-run-checks`
- `/aidd-complete-phase`
- `/aidd-validate`
- `/aidd-ship-feature`
- `/aidd-init`
