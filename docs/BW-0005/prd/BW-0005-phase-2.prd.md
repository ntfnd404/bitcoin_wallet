# BW-0005 Phase 2 PRD — Remove `HdAddressEntry`, Use `Address` Directly

Status: `PRD_READY`
Ticket: BW-0005
Phase: 2
Lane: Critical
Workflow Version: 3
Owner: Analyst

---

## Phase Intent

`transaction/HdAddressEntry` duplicates a strict subset of `address/Address`.
There is no architectural cycle that justifies the duplication: it exists
because the `transaction` package historically did not depend on `address`.
Every `Address` change today forces a parallel `HdAddressEntry` update, and
the duplication will silently grow as the HD send flow needs more address
metadata.

This phase removes `HdAddressEntry`, declares an explicit `transaction →
address` dependency in `pubspec.yaml`, and routes every transaction code
path that previously consumed `HdAddressEntry` (notably `HdAddressDataSource`
and the HD send preparation flow) through the canonical `Address` entity.

The phase is **Critical lane** because the affected code paths sit on the
hot path of HD signing: `HdAddressDataSource` feeds `PrepareHdSendUseCase`,
which constructs `SigningInput` for `keys/SignTransactionUseCase`. Any
mistake here can change which UTXO is signed with which key, corrupt
derivation-path metadata, or expose private material if cross-imports leak.
Behaviour must remain bit-identical and reference-vector signing tests must
remain green.

---

## Deliverables

1. `transaction/pubspec.yaml` declares `address` as a path dependency, with an
   exact version (no `^`), placed alphabetically.
2. `packages/transaction/lib/src/domain/value_object/hd_address_entry.dart`
   deleted from the working tree.
3. `HdAddressDataSource` (in `transaction/domain/data_sources/`) and every
   downstream consumer (HD send preparation, related use cases, the in-app
   adapter `lib/core/adapters/hd_address_data_source_impl.dart`) updated to
   exchange `Address` instead of `HdAddressEntry`.
4. All unit/integration tests touching the removed type updated to use
   `Address`. Test count must not drop; semantics of asserted scenarios must
   be preserved.
5. Reference-vector signing tests (HD signing path through
   `keys/SignTransactionUseCase`) remain green and unmodified except where a
   constructor argument changes type.
6. Security-reviewer artifact authored under
   `docs/BW-0005/security/phase-2-security.md` (Critical-lane gate).
7. Phase progress recorded in `docs/BW-0005/tasklist-BW-0005.md` and the
   phase log under `docs/BW-0005/phase/`.

---

## Scenarios

### Positive

- A grep for `HdAddressEntry` across the repo (excluding `docs/BW-0005/`)
  returns zero matches after the phase.
- `PrepareHdSendUseCase` receives `List<Address>` (or an equivalent typed
  collection of `Address`) from `HdAddressDataSource`, matches each scanned
  UTXO to its address by string equality, and produces the same
  `SigningInput` set it produced before — verified by a signing reference
  vector test.
- `transaction/pubspec.yaml` declares `address: path: ../address` (or the
  equivalent workspace form), and `dart pub get` succeeds across the
  workspace.
- `dart pub deps` shows no cycle: `address` does not gain a back-edge to
  `transaction`.
- All BW-0003 reference vectors (legacy/P2SH-P2WPKH/P2WPKH/P2TR signing)
  still produce identical signatures and witness layouts.

### Negative / Edge

- Adding `transaction → address` accidentally introduces a cycle because
  `address` later imports something from `transaction`: must be detected by
  `dart pub deps` and rejected before merge.
- A consumer site silently widens its public surface to expose
  `derivationPath` where it was previously hidden: the public surface of
  every affected use case must be reviewed; any new field exposure requires
  explicit justification.
- A test that was asserting against `HdAddressEntry` is deleted instead of
  rewritten, dropping coverage: forbidden — test count must not drop and the
  scenario coverage matrix must be preserved.
- A code path mismatches a UTXO to the wrong `Address` because of equality
  semantics differences between the old type and the new one (e.g.
  `Address` does not implement value equality): the matching logic must be
  defined explicitly (by `value` string comparison) and covered by a unit
  test.
- A logging/telemetry call is added that emits `Address.derivationPath` or
  any HD-private metadata into logs or error messages: forbidden by
  conventions; must be caught by security review.
- Refactor accidentally calls `keys/SignTransactionUseCase` with a different
  derivation path than before: caught by reference-vector signing tests
  remaining bit-identical.

---

## Success Metrics

| Criterion | Verification |
|-----------|--------------|
| `HdAddressEntry` source file removed | `test ! -e packages/transaction/lib/src/domain/value_object/hd_address_entry.dart` |
| No `HdAddressEntry` references remain | `grep -r "HdAddressEntry" packages/ lib/ test/` returns no rows (docs allowed) |
| `transaction → address` dependency declared | `grep -A2 'address:' packages/transaction/pubspec.yaml` shows the path entry |
| Workspace resolves cleanly | `dart pub get` exits 0 in repo root |
| No new dependency cycle | `dart pub deps` for `address` shows no path back to `transaction` |
| Reference-vector signing tests green | All BW-0003 signing reference tests pass with identical fixtures |
| Test suite green | `flutter test` exits 0; test count not lower than baseline |
| `dart analyze` clean | `flutter analyze --fatal-infos --fatal-warnings` exits 0 |
| Security-reviewer artifact exists | `test -f docs/BW-0005/security/phase-2-security.md` |
| `/aidd-run-checks` passes | Exit 0 |

---

## Constraints

- No behavioural change. The phase removes a duplicate type; it must not
  rename, repath, or alter how transactions are prepared or signed.
- `Address` remains owned by the `address` package. The `transaction`
  package becomes a consumer; it must not extend, subclass, or wrap
  `Address` to add transaction-specific fields. If transaction-only
  metadata is required, surface the open question rather than inventing a
  new wrapper in this phase.
- `transaction → address` is the only new dependency. No other package
  edge is added or removed.
- DataSource interface ownership rule from `conventions.md` is preserved:
  `HdAddressDataSource` remains owned by the `transaction` package
  (consumer owns the contract); only its method signatures change.
- Imports are `package:`-style; no relative imports.
- All documentation updates and commit messages are written in English.
- No `print`, no `dynamic`, no `!` null assertion in modified files.
- Tests may be **rewritten** (rename of type, change of constructor
  arguments) but must not be **deleted** unless the scenario they cover is
  trivially subsumed by another test — in which case the planner must
  document the equivalence in the implementation plan.

### Security / Privacy Constraints (Critical Lane)

- **No key material may move into wider-visibility layers.** Private keys,
  WIFs, and seed bytes remain inside the `keys` package. `Address` does
  not carry key material; this phase must not change that invariant.
- **Signing-call sites stay inside the keys boundary.** This phase touches
  the construction of `SigningInput` upstream of
  `keys/SignTransactionUseCase`, but does not move signing logic out of
  the `keys` package. No code outside `keys/` may gain the ability to
  sign.
- **Reference-vector signing tests must remain green and unmodified**
  beyond constructor-type changes. A passing reference vector is the
  primary proof that no behavioural drift has occurred.
- **No telemetry, logging, or error-message surface gains access to
  private material or HD-private metadata** (derivation paths, indices,
  xpubs). The security review must explicitly verify that no new
  log/`developer.log`/error site emits these fields.
- **`derivationPath` exposure audit.** `Address.derivationPath` is HD
  metadata; it is non-secret but linkable. The security review must
  confirm it is not newly exposed to the UI layer or to `bitcoin_node`
  RPC payloads.
- **No new code path inside `transaction/` may import from `keys/src/`.**
  Only the public `keys` API may be consumed.
- A security-reviewer artifact must be written under
  `docs/BW-0005/security/phase-2-security.md` covering the four bullets
  above before the phase is marked complete.

---

## Out Of Scope

- Splitting `wallet/`, `transaction/`, `address/` into HD/Node subfolders
  (Phase 3).
- Adding new use cases, new data sources, or new RPC methods.
- Changing the public surface of `keys` or any signing logic.
- Authoring package `README.md` files or rewriting `architecture.md`
  (Phase 4).
- Reorganising `bitcoin_node/` (already done in Phase 1).
- Introducing value equality on `Address` beyond what the matching logic
  strictly requires.

---

## Open Questions

- [ ] If `transaction` later needs address metadata that is conceptually
  transaction-specific (e.g. "is this a change address?"), is the chosen
  pattern to extend `Address` in the `address` package, or to introduce a
  transaction-side projection? Default proposal: prefer extending `Address`
  in its owner module; revisit in a follow-up ticket if the need arises.
  This question is informational and does not block Phase 2.
