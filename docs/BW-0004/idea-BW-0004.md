# Idea: Unified Send with UTXO Selection (BW-0004)

Status: `IDEA_READY`
Ticket: BW-0004
Phase: feature
Lane: Critical
Workflow Version: 3
Owner: Product / Architect
Date: 2026-04-24
Depends On: [BW-0003]
Blocked Until: none

---

## Problem

The app currently has two disconnected send flows:
- `feature/send/` — production send with automatic coin selection (named strategies)
- `feature/signing/manual_utxo/` — HD-only prototype with manual UTXO scan

Neither flow explains *why* specific UTXOs were chosen. The user has no visibility
into the trade-offs of each selection decision. The two flows are architecturally
inconsistent and cannot be composed.

---

## Business Goal

Provide a single unified send screen where the user can choose *how* UTXOs are
selected: let the app pick automatically (with explanation), choose a named strategy,
or handpick UTXOs manually. All three modes share the same signing and broadcast pipeline.

---

## Scope

- Unified send entry point with three UTXO selection modes
- **Auto mode**: algorithm picks the best strategy and explains the reasoning to the user
- **Strategy mode**: user picks a named coin selection strategy; app shows trade-offs per strategy
- **Manual mode**: user selects individual UTXOs from a checklist; app shows running totals and warnings
- Coin selection domain interfaces: `UtxoSelectionStrategy`, `AutoUtxoSelector`
- Strategies v1: Branch and Bound, Largest-first, Smallest-first, FIFO, Random
- Absorb `feature/signing/manual_utxo/` into `feature/send/manual/`
- HD wallets only for manual mode (requires key derivation); Node + HD for auto/strategy

### Non-goals

- Privacy / coin control labelling
- Fee bumping (RBF / CPFP)
- Multi-recipient transactions
- Batch sending
- Mainnet / real funds

---

## User Stories

- As an HD wallet user, I want the app to automatically pick the best UTXOs and explain why, so I don't need to understand coin selection myself.
- As a power user, I want to pick a named strategy (BnB, FIFO, etc.) and see the trade-offs before confirming.
- As a developer, I want to manually select UTXOs so I can test specific spending scenarios on regtest.

---

## Dependencies

- BW-0003 (HD key derivation, signing pipeline) — closed ✅
- `packages/transaction` — ScanUtxosUseCase, BroadcastTransactionUseCase already exist
- `packages/keys` — SignTransactionUseCase already exists

---

## Acceptance Criteria

| Criterion | Verification |
|-----------|--------------|
| Auto mode selects UTXOs and shows human-readable reasoning | Manual test: open auto send, verify reasoning text shown |
| Strategy mode shows all 5 strategies with fee/change estimates | Manual test: open strategy picker, verify cards |
| Manual mode allows UTXO checkbox selection with running total | Manual test: select UTXOs, verify total updates |
| All three modes successfully broadcast a transaction on regtest | Manual test: broadcast from each mode, confirm via getrawtransaction |
| `signing/manual_utxo/` removed — absorbed into `send/manual/` | flutter analyze clean, no old imports |
| Domain interfaces in `packages/transaction`, not in feature layer | Reviewer confirms layer boundaries |

---

## Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| BnB algorithm complexity (NP-hard subset sum) | Medium | Use time-bounded search with fallback to largest-first |
| Auto-selector explanation quality (not useful to user) | Medium | Define explanation template in PRD, review with QA |
| Manual UTXO migration breaks existing signing tests | Low | Keep SigningBloc logic intact, only move location |

---

## Open Questions

- [ ] Should auto mode skip the explanation screen for experienced users (preference toggle)?
- [ ] Fee rate source: hardcoded default, user input, or mempool estimate?
- [ ] Should strategy selection persist across sessions?
