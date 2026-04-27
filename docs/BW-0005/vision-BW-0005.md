# Vision: Architecture Refactor + Package Documentation (BW-0005)

Status: `VISION_APPROVED`
Ticket: BW-0005
Phase: feature
Lane: Critical
Workflow Version: 3
Owner: Researcher / Architect
Date: 2026-04-25

---

## Problem Summary

Four pieces of architectural debt were inherited from BW-0001..BW-0003 and
must be paid down before BW-0004 unified-send resumes, otherwise the next
feature will codify them further:

1. `packages/bitcoin_node/lib/src/` is flat: eleven `*.dart` files sit
   directly under `src/` with no folder-level signal of which consumer
   module each adapter serves.
2. `transaction/HdAddressEntry` (in
   `packages/transaction/lib/src/domain/value_object/hd_address_entry.dart`)
   duplicates a strict subset of `address/Address`. There is no architectural
   cycle that justifies it — the `transaction` package simply does not yet
   declare a path dependency on `address`.
3. The HD (non-custodial) and Node (custodial) trust models are interleaved
   inside the `data/` and `application/` layers of `wallet`, `transaction`,
   and `address`. Cross-trust imports are review-only concerns; no folder
   boundary makes them structurally visible.
4. All nine workspace packages (`address`, `bitcoin_node`, `keys`,
   `rpc_client`, `shared_kernel`, `storage`, `transaction`, `ui_kit`,
   `wallet`) ship without a `README.md`. `docs/project/architecture.md`
   omits the `transaction` package entirely and shows a stale pre-BW-0002
   snapshot of `bitcoin_node` plus an outdated dependency graph.

The architectural intent of BW-0005 is to make the existing layered + DDD +
hexagonal foundation **enforceable by directory layout alone**, then capture
that state in writing so future contributors and the analyst/planner agents
can plan against truth rather than against memory.

---

## Current System State

Workspace (root `pubspec.yaml` lines 9–18) declares exactly nine packages:
`address`, `bitcoin_node`, `keys`, `rpc_client`, `shared_kernel`, `storage`,
`transaction`, `ui_kit`, `wallet`.

Real package dependency edges (from each `packages/*/pubspec.yaml`):

```
shared_kernel  → (none)
ui_kit         → flutter
rpc_client     → http
storage        → shared_kernel, flutter, flutter_secure_storage
keys           → shared_kernel, crypto, pointycastle
wallet         → shared_kernel, keys, uuid
address        → shared_kernel, keys, wallet
transaction    → shared_kernel
bitcoin_node   → shared_kernel, rpc_client, wallet, address, transaction
```

App-level (`pubspec.yaml`) depends on every workspace package.

Trust-distinguishing entities live in `packages/wallet/lib/src/domain/entity/`
as a sealed `Wallet` with `HdWallet` and `NodeWallet` parts. HD addresses
carry `derivationPath`; Node addresses carry `derivationPath = null`
(`packages/address/lib/src/domain/entity/address.dart` lines 11–14).

`HdAddressEntry` is referenced in exactly four locations:
`packages/transaction/lib/src/domain/value_object/hd_address_entry.dart`,
`packages/transaction/lib/src/domain/data_sources/hd_address_data_source.dart`,
`lib/core/adapters/hd_address_data_source_impl.dart`, and the consumer
`packages/transaction/lib/src/application/prepare_hd_send_use_case.dart`
(uses `entry.address`, `entry.index`, `entry.type`).

Adapters bridging features and packages live at
`/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/lib/core/adapters/`
(`hd_address_data_source_impl.dart`, `hd_transaction_signer.dart`).

Tests exist under `packages/keys/test/`, `packages/rpc_client/test/`,
`packages/transaction/test/transaction_test.dart`, and the root mirror
`test/feature/{wallet,address}/domain/usecase/`. There are currently no
tests under `packages/wallet/test/`, `packages/address/test/`, or
`packages/bitcoin_node/test/`.

`docs/project/architecture.md` lines 89–171 still document the pre-BW-0002
package layout: it lists only `wallet`, `address`, `keys`, plus
`bitcoin_node` flat. It omits `transaction` entirely; its dependency
diagram (lines 22–62) shows `bitcoin_node → wallet, address, rpc_client`
but not `→ transaction`; its `Avoiding Cycles` section (lines 312–326)
prescribes `address → wallet` but does not mention `transaction`.

---

## Architecture Decisions

| Decision | Rationale | ADR / Reference |
|----------|-----------|-----------------|
| HD vs Node split is a **subfolder boundary inside existing packages**, not a separate-package split | Trust-model logic shares the same domain types (`Address` carries `derivationPath?`, `Wallet` is sealed with `HdWallet`/`NodeWallet`); a separate-package split would duplicate domain entities and generate import friction. Subfolder-level structure is enough to make cross-trust imports greppable | `docs/project/adr/ADR-002-trust-model-subfolder-split.md` |
| `domain/` layers stay shared across trust models | Confirmed by user 2026-04-25 (Phase 3 PRD Open Q resolved). Sealed entity hierarchy plus nullable `derivationPath` already encodes the trust distinction at the type level | Phase 3 PRD §Open Questions |
| `transaction → address` becomes an explicit path dependency | `address` never imports from `transaction` (verified by grep across `packages/address`), so the new edge does not introduce a cycle. Removing `HdAddressEntry` removes parallel-update debt | Phase 2 PRD §Phase Intent |
| `bitcoin_node` reorganises by **consumer module**, not by Clean-Architecture layer | Each adapter implements exactly one consumer interface; consumer-aligned layout shows ownership at a glance and matches the existing per-consumer barrel structure | Phase 1 PRD §Deliverables |
| Phase 4 documents nine packages, not ten | Workspace declaration in root `pubspec.yaml` lists exactly nine packages; `domain/` is a layer inside packages, not a separate workspace package (confirmed 2026-04-25) | Phase 4 PRD §Deliverables |
| Phase ordering: 1 → 2 → 3 → 4 | Phase 1 is the lowest-risk move (no domain change); Phase 2 establishes `Address` as canonical before Phase 3 splits address-touching code by trust model; Phase 4 captures the post-refactor truth in writing | Idea §Scope |

---

## Boundaries

### In scope

- Reorganise `packages/bitcoin_node/lib/src/` into five consumer-aligned
  subfolders and update every importer.
- Remove `HdAddressEntry`, declare `transaction → address`, route every
  HD send-preparation site through `Address`.
- Introduce `hd/` and `node/` subfolders inside `data/` **and**
  `application/` of `wallet`, `transaction`, `address`. Update DI assemblies
  (`wallet_assembly.dart`, `transaction_assembly.dart`,
  `address_assembly.dart`) and the in-app feature scope
  (`lib/feature/send/di/send_scope.dart`).
- Author nine package READMEs and rewrite `docs/project/architecture.md`
  so the dependency graph and per-package layout match
  `pubspec.yaml` reality.
- Add a `conventions.md` rule that any layer-structure change must touch
  the package README in the same PR.

### Out of scope

- Any user-facing feature work. BW-0004 unified-send remains paused.
- Any change inside `packages/keys/` (signing logic, derivation, seed
  storage are untouched).
- Splitting `domain/` layers of `wallet`, `transaction`, or `address`.
- Introducing static-analysis rules to enforce the trust boundary
  (greppable check is sufficient for this ticket; tooling is a follow-up).
- New use cases, repositories, data sources, RPC methods, or test
  scenarios.
- Behavioural changes of any kind — every reference-vector signing test
  from BW-0003 must remain bit-identical.

---

## Key Interfaces And Data Flows

The ticket changes structure, not contracts. The four touchpoints below
keep the same semantics before and after.

```dart
// Phase 2: HdAddressDataSource changes only the type it returns.
abstract interface class HdAddressDataSource {
  Future<List<Address>> getAddressesForWallet(String walletId); // was List<HdAddressEntry>
}

// Phase 3: barrels keep an identical exported symbol set.
// wallet.dart, transaction.dart, address.dart export the same identifiers
// after the hd/ and node/ subfolders move; only export paths change.

// HD send flow remains:
// HdAddressDataSource → PrepareHdSendUseCase → SigningInput[]
//   → HdTransactionSigner (lib/core/adapters/) → keys/SignTransactionUseCase
```

Trust-boundary invariant after the refactor:

```
hd/* files       must import only from: hd/, layer-root shared/, domain/, other packages
node/* files     must import only from: node/, layer-root shared/, domain/, other packages
hd/* files       must NOT import from node/ within the same package
node/* files     must NOT import from hd/ within the same package
keys package     remains the only signing-capable code
private material never crosses any package, layer, or subfolder boundary
```

---

## Risks And Follow-ups

- **ADR authored.** `docs/project/adr/ADR-002-trust-model-subfolder-split.md`
  records the durable architectural commitment that HD and Node are
  subfolders within the same business package (not separate workspace
  packages), and that `domain/` layers stay shared across trust models.
  This ADR is the canonical reference for any future trust-model addition
  (e.g. multisig, hardware wallet) and for reviewer checklists on
  `wallet`, `transaction`, `address` PRs.
- **Critical-lane phases (2, 3) sit on the HD signing hot path.** Phase 2
  changes the type produced by `HdAddressDataSource` and consumed by
  `PrepareHdSendUseCase`; Phase 3 moves files that contribute to
  `SigningInput` construction. Mitigation: BW-0003 reference vectors must
  remain green and bit-identical; security review is gated per phase.
- **The reorganised tree must not leak HD-private metadata into wider
  layers.** `Address.derivationPath` is non-secret but linkable; the
  Phase 2 review must confirm it is not newly exposed to UI or RPC
  payloads, and the Phase 3 review must confirm `node/` subfolders never
  import HD context.
- **Test coverage gaps.** `packages/wallet/`, `packages/address/`, and
  `packages/bitcoin_node/` have no in-package tests; their consumers'
  tests live at `test/feature/...`. Phases 1 and 3 must move tests in
  lockstep with sources or risk broken discovery — `guidelines.md`
  requires test paths to mirror source paths.
- **Documentation drift after Phase 4.** READMEs are easy to ship and
  hard to keep current. The Phase 4 deliverable adds a process rule to
  `conventions.md` that any layer-structure change touches the README in
  the same PR. There is no CI enforcement; reviewer discipline is the
  only barrier.
- **BW-0004 divergence.** While BW-0005 ships in four PRs, BW-0004 stays
  paused on its own branch. If BW-0004 must move, it should rebase onto
  `main` after each BW-0005 phase merges so the structural changes flow
  forward incrementally rather than in one large rebase at the end.

---

## Open Questions

- [ ] None — all locked-decision items are resolved per PRDs (Phase 3
  domain stays shared; Phase 4 documents nine packages). The four
  architectural decisions in the table above are derived from those
  resolved decisions and the verified codebase state.
