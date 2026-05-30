# Project Roadmap

Last reviewed: 2026-05-26

## Completed tickets

- BW-0012 — Send flow foundation (merged to main).
- BW-0013 — Address & wallet hardening (merged to main).
- BW-0014 — Transaction lifecycle integration (merged to main).
- BW-0015 — Bitcoin Script + QR code + `getrawtransaction` verification (merged to main).
- BW-0016 — Manual UTXO selection (merged to main; closed REVIEW_OK + QA_PASS; three known code smells explicitly carried forward to BW-0018).
- BW-0018 phases 1-2 — `UtxoSource` contract + 4 implementations + `EligibilityFilteringUtxoSource` decorator (commit `251b1f0`); `Signer` contract + `NodeRpcSigner` + `HdInAppSigner` (commit `a376091`). Both phases REVIEW_OK + SECURITY_REVIEW_OK + QA_PASS.

## In-flight tickets

- BW-META-001 — AIDD v3.2 spec-first hardening + Trivial lane adoption. Critical lane. Phase 1 QA_PASS, Phase 2 QA_PASS, Phase 3 in progress (knowledge persistence + phase-dir flatten). Phase 4 pending.
- BW-0018 — Send architecture refactor. Phases 1-2 merged to main; Phases 3-6 DEFERRED until BW-META-001 ships so the remaining phases run under v3.2 conventions (structured AC, Clarification round, spec-critic gate).

## Planned

- BW-0017 — Typed routes & feature composition (routing refactor). Plan drafted; ticket not yet opened. Branches from main after BW-META-001 lands. Critical lane. Replaces lifecycle-fragile nested `AppRouterDelegate` scopes with sealed `AppRoute` + per-feature `<X>Entry` composition roots; ADRs the `go_router` rejection.
- BW-0019 — HD-pinned UI surfacing. Reserved namespace in BW-0018 tasklist; idea stub authored at the close of BW-0018 Phase 6.
- Phase 08 — Polish & demo. iOS / Android / macOS / web builds; one-command README demo; full end-to-end user stories.

## Deferred / open items

- BW-0018 phase-dir migration (`docs/BW-0018/phase/BW-0018/` → `docs/BW-0018/phase/`). Explicitly exempted from BW-META-001 Phase 3 Item 12. Validator carries a dual-path matcher until the BW-0018 owner opts in.
- BW-0018 carry-forwards F1, F2-1 … F2-5 (NodeRpcSigner missing `await`, `KeysException` narrowing, `SigningInput.toString()` exposure, unknown-pinned-input UI scrub, no-`print`-in-adapters lint). All to be closed inside BW-0018 phases 3-6 once resumed; F1/F2-1 become moot after ADR-002 D-S6 lands.
- Used/unused address label (from BW-0012 Phase 03). Low priority; needs address tracking. Tracked as a separate future ticket.

## Last 3 changes

- 2026-05-26 — Initial roadmap committed (BW-META-001 Phase 3 Batch 2).
- 2026-05-25 — BW-0018 status checkpoint recorded: Phases 1-2 merged, Phases 3-6 deferred pending BW-META-001.
- 2026-05-21 — BW-0016 closed (manual UTXO selection), code smells carried to BW-0018.
