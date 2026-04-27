# BW-0005 Phase 1 PRD — Reorganise `bitcoin_node` by Consumer Module

Status: `PRD_READY`
Ticket: BW-0005
Phase: 1
Lane: Professional
Workflow Version: 3
Owner: Analyst

---

## Phase Intent

Today the `bitcoin_node` adapter package keeps every implementation file directly
under `packages/bitcoin_node/lib/src/` (eleven files side-by-side). There is no
folder-level signal showing which consumer each adapter serves, so navigation,
review, and ownership decisions all require reading source.

This phase relocates the existing files into five consumer-aligned subfolders —
`wallet/`, `address/`, `transaction/`, `utxo/`, `block/` — and updates every
import path that points into `bitcoin_node`. It is a **pure structural move
with zero behavioural change**, executed before BW-0004 unified-send begins so
that the new code lands on a structure that already encodes consumer intent.

This is a Professional-lane phase: no key material, no signing logic, and no
domain entity is touched.

---

## Deliverables

1. Five new subfolders under `packages/bitcoin_node/lib/src/`:
   `wallet/`, `address/`, `transaction/`, `utxo/`, `block/`.
2. All current `*.dart` files under `packages/bitcoin_node/lib/src/` relocated
   into the subfolder matching the consumer module they serve. After the move
   no `*.dart` file remains directly under `lib/src/`.
3. The `bitcoin_node` public barrel (`lib/bitcoin_node.dart`) updated to export
   the new paths; its public API surface is identical to the pre-phase state
   (same set of exported symbols, no additions, no removals).
4. All in-repo imports referencing the moved files updated, both inside
   `bitcoin_node/` and across every consumer (`packages/*/`, `lib/`, `test/`).
5. All existing tests remain green; no test is added, removed, deleted, or
   marked `skip`.
6. Phase progress recorded in `docs/BW-0005/tasklist-BW-0005.md` and the
   phase log under `docs/BW-0005/phase/`.

---

## Scenarios

### Positive

- A reviewer opening `packages/bitcoin_node/lib/src/` sees five subfolders
  whose names match the consuming module; clicking into `transaction/` reveals
  only adapters used by the `transaction` package.
- A consumer that previously imported `package:bitcoin_node/bitcoin_node.dart`
  continues to compile without changes — barrel re-exports preserve the symbol
  set.
- `dart analyze` and the full unit/integration test suite pass on every
  supported platform target.
- `/aidd-run-checks` exits 0; no warnings, no infos, no `skip:` markers added.

### Negative / Edge

- An import path is missed during the move and a downstream package fails to
  compile: must surface as an analyzer error in the phase's check run, not at
  runtime.
- A file is placed in the wrong subfolder (e.g. a transaction adapter into
  `wallet/`): caught by reviewer checklist; no such mis-classification ships.
- A consumer reaches into `package:bitcoin_node/src/...` directly instead of
  the public barrel: such imports must be rewritten to the barrel during this
  phase, not perpetuated.
- A file moved between folders accidentally changes its public symbol set
  (e.g. a class made `private`): forbidden — the public API of `bitcoin_node`
  must be byte-equivalent in symbol terms before and after the phase.
- A new dependency cycle is introduced because the new subfolder structure
  exposes a previously-hidden cross-import: must be detected by `dart pub
  deps` review and resolved before the phase closes.

---

## Success Metrics

| Criterion | Verification |
|-----------|--------------|
| Five subfolders exist under `packages/bitcoin_node/lib/src/` | `ls packages/bitcoin_node/lib/src/` lists exactly `wallet/ address/ transaction/ utxo/ block/` (plus no `*.dart` files) |
| No `.dart` file remains directly under `lib/src/` | `find packages/bitcoin_node/lib/src/ -maxdepth 1 -name '*.dart'` returns no rows |
| Public barrel still exports the same symbol set | Manual diff of `lib/bitcoin_node.dart` exported identifiers before/after |
| All in-repo imports updated | `grep -r "package:bitcoin_node/src/" packages/ lib/ test/` returns only the new paths |
| `dart analyze` clean | `flutter analyze --fatal-infos --fatal-warnings` exits 0 |
| Test suite green and unchanged in count | Test count before == test count after; no `skip:` added |
| `dart pub deps` clean for `bitcoin_node` and every consumer | No cycles; dependency graph unchanged |
| `/aidd-run-checks` passes | Exit 0 |

---

## Constraints

- Pure structural change. No behaviour change, no public API change, no
  domain logic touched.
- No new tests added; no existing test deleted or marked `skip`. The phase's
  goal is invariant preservation.
- Hexagonal layering and DataSource ownership rules from `conventions.md`
  remain intact: DataSource interfaces stay in their consumer modules
  (`wallet/domain/data_sources/`, `address/domain/data_sources/`,
  `transaction/domain/data_sources/`); only the implementations inside
  `bitcoin_node/` are reorganised.
- `bitcoin_node` continues to depend only on the packages it depends on today.
  No new package dependency is added.
- Imports remain `package:`-style (no relative imports), per the prohibited
  list in `conventions.md`.
- All commit messages and documentation updates are written in English.
- README files for packages are **not** authored in this phase — that is
  Phase 4's deliverable.
- The HD vs Node trust-model split inside `wallet/`, `address/`, `transaction/`
  is **not** introduced here — that is Phase 3's deliverable.
- No `print`, no `dynamic`, no null assertion (`!`) appears in moved files
  (carry-over of pre-existing constraints; phase must not regress them).

---

## Out Of Scope

- Removing or replacing `transaction/HdAddressEntry` (Phase 2).
- Splitting `wallet/`, `address/`, `transaction/` by trust model (Phase 3).
- Authoring package `README.md` files or rewriting `architecture.md`
  (Phase 4).
- Adding new adapters, new data sources, or new RPC methods.
- Changing the public surface of `bitcoin_node` or any consumer module.
- Refactoring inside the `keys` package.

---

## Open Questions

- [ ] None
