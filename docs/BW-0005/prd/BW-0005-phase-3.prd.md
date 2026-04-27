# BW-0005 Phase 3 PRD — HD/Node Subfolders by Trust Model

Status: `PRD_READY`
Ticket: BW-0005
Phase: 3
Lane: Critical
Workflow Version: 3
Owner: Analyst

---

## Phase Intent

The `wallet/`, `transaction/`, and `address/` packages today interleave HD
(non-custodial, app owns keys) and Node (custodial, Bitcoin Core owns keys)
implementations in the same folders. Every flow already has to branch on
trust model — `create_hd_wallet_use_case.dart` next to
`create_node_wallet_use_case.dart`, `prepare_hd_send_use_case.dart` next to
`prepare_node_send_use_case.dart`, `hd_address_generation_strategy.dart`
next to `node_address_generation_strategy.dart`.

Without a folder-level boundary, a future change can silently import HD
state into Node code (or vice versa) and the violation only surfaces in
review, not in structure. This phase introduces explicit `hd/` and `node/`
subfolders inside the `data/` and `application/` layers of each of the
three packages, splits existing files into them, and verifies that no HD
file imports from a `node/` folder and vice versa within the same package.

This is **Critical lane** because the trust-model boundary is the central
security invariant of the wallet: a misplaced import that lets Node code
reach into HD signing context (or that lets HD code reach for Node RPC
sessions) is a privacy/security regression even if it does not change
runtime behaviour today.

---

## Deliverables

1. In `packages/wallet/`:
   - `data/hd/` and `data/node/` subfolders containing the trust-specific
     repository/data-source implementations (e.g. HD-only flows separated
     from Node-only flows).
   - `application/hd/` and `application/node/` subfolders containing the
     trust-specific use cases (`create_hd_wallet_use_case`,
     `restore_hd_wallet_use_case` → `hd/`; `create_node_wallet_use_case`
     → `node/`).
2. In `packages/transaction/`:
   - `application/hd/` and `application/node/` subfolders containing the
     trust-specific send/preparation use cases
     (`prepare_hd_send_use_case`, `send_hd_transaction_use_case`,
     `hd_send_preparation` → `hd/`; `prepare_node_send_use_case`,
     `send_node_transaction_use_case`, `node_send_preparation` →
     `node/`).
   - `data/` mirroring the same `hd/` vs `node/` split where
     trust-specific implementations exist.
3. In `packages/address/`:
   - `data/` and `application/` mirroring the same split, with at minimum
     `hd_address_generation_strategy` → `application/hd/` and
     `node_address_generation_strategy` → `application/node/`.
4. Shared (trust-agnostic) files inside `data/` and `application/` remain
   at the layer root (not pushed into either subfolder). The planner is
   responsible for classifying each file; this PRD requires the
   classification to be explicit and reviewable.
5. All in-repo imports updated; public barrels (`*.dart`,
   `*_assembly.dart`) preserve the same exported symbol set.
6. DI registration sites in `*_assembly.dart` files and feature scopes
   (e.g. `lib/feature/send/di/send_scope.dart`) updated to reference the
   new paths.
7. A reviewable check that **no file in any `hd/` subfolder imports from
   any `node/` subfolder, and vice versa, within the same package**.
8. `domain/` layers of all three packages remain unchanged in structure
   (entities and interfaces stay shared — see Open Questions).
9. All existing tests remain green; no test deleted or marked `skip`.
10. Security-reviewer artifact authored under
    `docs/BW-0005/security/phase-3-security.md` (Critical-lane gate).
11. Phase progress recorded in `docs/BW-0005/tasklist-BW-0005.md` and the
    phase log under `docs/BW-0005/phase/`.

---

## Scenarios

### Positive

- A reviewer opening `packages/wallet/lib/src/application/` sees `hd/`
  and `node/` subfolders, each holding only that trust model's use
  cases. The same shape appears in `packages/transaction/lib/src/` and
  `packages/address/lib/src/`.
- Public APIs of the three packages are unchanged: importers continue to
  use the package barrel and assembly entry points without source
  edits.
- DI assembly classes register the same set of bindings; the feature
  layer continues to receive the same use cases through the same scope
  contracts.
- A grep confirming `hd/` files do not reference `node/` (and vice
  versa) within the same package returns no violations.
- Full test suite green; reference-vector signing tests untouched and
  passing.

### Negative / Edge

- A use case that orchestrates **both** HD and Node concerns is
  classified into one subfolder, creating a forbidden cross-trust
  import: such a file must remain at the `application/` layer root
  (trust-agnostic) and explicitly accept both code paths via dependency
  injection rather than direct import. Any genuinely
  cross-trust orchestration must be flagged for review.
- A file is moved into `hd/` but the corresponding test is not relocated
  alongside it, breaking test discovery: forbidden — tests must mirror
  source structure (per `guidelines.md`).
- A new dependency cycle appears because the subfolder split exposes a
  shared helper: must be detected by `dart pub deps` and resolved before
  the phase closes.
- A barrel file (`wallet.dart`, `transaction.dart`, `address.dart`)
  changes its exported symbol set during the move: forbidden — symbol
  set must be byte-equivalent before and after.
- DI assembly in `wallet_assembly.dart` / `transaction_assembly.dart` /
  `address_assembly.dart` accidentally registers an HD implementation
  where a Node one is expected (or vice versa) because of an import
  swap: caught by integration tests and DI smoke check; no such
  regression ships.
- `lib/core/adapters/hd_address_data_source_impl.dart` (app-side
  adapter) imports from a `node/` subfolder of `transaction/`:
  forbidden cross-trust leak; must be rejected.

---

## Success Metrics

| Criterion | Verification |
|-----------|--------------|
| `packages/wallet/lib/src/application/` contains `hd/` and `node/` | `ls` shows both subfolders |
| `packages/wallet/lib/src/data/` contains `hd/` and `node/` (where applicable) | `ls` shows both subfolders |
| Same shape in `packages/transaction/lib/src/{application,data}/` | `ls` shows both subfolders in each layer |
| Same shape in `packages/address/lib/src/{application,data}/` | `ls` shows both subfolders in each layer |
| No HD file imports from a `node/` folder in the same package | `grep -r "src/.*/node/" packages/<pkg>/lib/src/.*/hd/` returns no rows for each of the three packages |
| No Node file imports from an `hd/` folder in the same package | `grep -r "src/.*/hd/" packages/<pkg>/lib/src/.*/node/` returns no rows for each of the three packages |
| Public barrels export identical symbol sets | Manual diff of exported identifiers in `wallet.dart`, `transaction.dart`, `address.dart` before/after |
| `dart pub deps` clean (no new cycles) | Verified for each modified package |
| Test suite green and unchanged in count | `flutter test` exits 0; test count not lower than baseline |
| Reference-vector signing tests still pass bit-identically | BW-0003 vectors green with identical fixtures |
| `dart analyze` clean | `flutter analyze --fatal-infos --fatal-warnings` exits 0 |
| Security-reviewer artifact exists | `test -f docs/BW-0005/security/phase-3-security.md` |
| `/aidd-run-checks` passes | Exit 0 |

---

## Constraints

- The durable architectural commitment behind this phase is recorded in
  `docs/project/adr/ADR-002-trust-model-subfolder-split.md`. Implementation
  must respect every invariant listed in that ADR's Decision section.
- No behavioural change. Pure structural split + import updates.
- `domain/` folders of `wallet/`, `transaction/`, and `address/` are not
  reorganised in this phase. Domain entities and interfaces stay shared
  across trust models (see Open Questions for the proposed default).
- DataSource ownership rules from `conventions.md` remain intact:
  contracts stay in their consumer module's `domain/data_sources/`;
  implementations live in `data/` and may move into `data/hd/` or
  `data/node/`.
- The `keys` package is not touched in this phase. Trust-model
  separation in `keys` (HD-private vs Node-irrelevant) is a separate
  concern and remains as-is.
- The `bitcoin_node` package is not reorganised again in this phase
  (Phase 1 already split it by consumer module).
- Public package APIs (`wallet.dart`, `transaction.dart`, `address.dart`,
  and the `*_assembly.dart` entry points) keep an identical exported
  symbol set.
- Imports remain `package:`-style.
- All commit messages and documentation updates are written in English.
- No new use case, repository, or data source is introduced. No existing
  behaviour is modified.
- Tests may be relocated to mirror new source paths but must not be
  deleted, renamed away from their scenario, or marked `skip`. Test
  count must not drop.
- No `print`, no `dynamic`, no `!` null assertion in modified files.

### Security / Privacy Constraints (Critical Lane)

- **The HD/Node split is a security boundary, not just an organisational
  one.** No file under any package's `hd/` subfolder may import from any
  `node/` subfolder of the same package, and vice versa. This must be
  verified by an explicit greppable check listed in the success
  metrics.
- **No key material crosses the split.** HD signing context (seed,
  derived keys, derivation paths) lives only in the `keys` package and
  is consumed only by `hd/` code paths. The phase must not create any
  call site outside `hd/` that touches HD-private inputs.
- **Node code paths must not gain access to HD-private metadata**
  (derivation paths, xpubs, indices) because of the move. The security
  review must verify that the `node/` subfolders import only
  trust-agnostic and Node-specific types.
- **Signing-call sites stay inside the keys boundary.** No code outside
  `packages/keys/` may gain the ability to sign as a side effect of the
  reorganisation.
- **Reference-vector signing tests remain green and unmodified.** A
  passing BW-0003 reference vector is the primary proof that the move
  caused no behavioural drift on the signing path.
- **No telemetry, logging, or error-message surface gains access to
  private material.** The security review must confirm that no new
  `developer.log`/error site emits seed, key, derivation-path, or xpub
  data.
- **DI registrations are part of the security surface.** The security
  review must verify that `wallet_assembly.dart`,
  `transaction_assembly.dart`, and `address_assembly.dart` register HD
  implementations only into HD-consumer flows and Node implementations
  only into Node-consumer flows — no swapped wires.
- **`lib/core/adapters/` app-side adapters** that bridge into `hd/`
  flows must not also bridge into `node/` flows (and vice versa).
- A security-reviewer artifact must be written under
  `docs/BW-0005/security/phase-3-security.md` covering the bullets
  above before the phase is marked complete.

---

## Out Of Scope

- Reorganising `bitcoin_node/` (Phase 1).
- Removing `HdAddressEntry` (Phase 2).
- Authoring package `README.md` files or rewriting `architecture.md`
  (Phase 4).
- Reorganising `domain/` layers of `wallet/`, `transaction/`,
  `address/`.
- Any change to the `keys`, `shared_kernel`, `storage`, `rpc_client`,
  `ui_kit`, or `bitcoin_node` package layouts.
- Any new use case, data source, repository, or RPC method.
- Introducing static analysis rules (e.g. `dart_code_metrics`) — the
  greppable check is sufficient for this phase; tooling enforcement is
  a follow-up.

---

## Open Questions

- [x] **Resolved.** Domain layers of `wallet/`, `transaction/`, and
  `address/` are not split. Only `data/` and `application/` get the
  `hd/` / `node/` subfolders. Domain entities and interfaces stay shared
  across trust models — `Address` already carries `derivationPath?` as
  the trust-distinguishing field, and the trust model itself lives as a
  field on `Wallet` rather than as a separate type. (Confirmed by user
  on 2026-04-25.)
- [ ] Some shared application-layer files (e.g. a future trust-agnostic
  send orchestrator, or `get_transactions_use_case`) do not belong in
  either `hd/` or `node/`. The planner must produce an explicit
  per-file classification matrix as part of the implementation plan;
  this PRD does not pre-classify those files.
