# Phase 2: Remove `HdAddressEntry`, Use `Address` Directly

Status: `IMPLEMENT_STEP_OK` (Batch 3 done — pending security-reviewer gate)
Ticket: BW-0005
Phase: 2
Lane: Critical
Workflow Version: 3
Owner: Implementer
Goal: Delete `HdAddressEntry`, add `transaction → address` dependency, route all reference sites through `Address`.

Session brief — execution packet only. See `docs/BW-0005/plan/BW-0005-phase-2.md` for full architecture rationale.

---

## Current Batch

All three batches are ready to execute in sequence.

**Batch 1 — Dependency declaration**
Edit `packages/transaction/pubspec.yaml` only; run resolver; verify no cycle.

**Batch 2 — Five source file edits + one deletion**
In order: data-source interface → adapter impl → use case → barrel → delete value object file.

**Batch 3 — Verification + security artifact**
Run all checks; author `docs/BW-0005/security/phase-2-security.md`.

---

## Constraints

- No behavioural change. No new logic. No test deletions.
- `transaction` imports only `package:address/address.dart` — do not import `package:wallet/` or `package:keys/` from within `transaction`.
- Use `package:` imports only — no relative imports.
- No `!` null-assertion operator in any modified line. No `dynamic`. No `print`.
- Always blank line before `return` when preceding code exists in the block.
- `Address.derivationPath` must not be read in any modified file — access only `Address.value`, `Address.index`, `Address.type`.
- `dart pub get` must be run before source edits that add `package:address/address.dart` imports inside `transaction`.
- Security-reviewer artifact is a gate — phase is not complete without `docs/BW-0005/security/phase-2-security.md`.

---

## Execution Checklist

### Batch 1 — pubspec

- [ ] 2.1 Edit `packages/transaction/pubspec.yaml`: add `address: path: ../address` under `dependencies` (alphabetically, before `shared_kernel`)
- [ ] 2.2 Run `dart pub get` from workspace root — exit 0
- [ ] 2.3 Run `dart pub deps address | grep transaction` — must return empty (no cycle)

### Batch 2 — source edits

- [ ] 2.4 Edit `packages/transaction/lib/src/domain/data_sources/hd_address_data_source.dart`:
  - Replace `import 'package:transaction/src/domain/value_object/hd_address_entry.dart';` with `import 'package:address/address.dart';`
  - Change return type to `Future<List<Address>>`
- [ ] 2.5 Edit `lib/core/adapters/hd_address_data_source_impl.dart`:
  - Remove `HdAddressEntry` import (no longer needed)
  - Change return type annotation to `Future<List<Address>>`
  - Replace `.map((a) => HdAddressEntry(...)).toList()` body with direct `return addresses;`
  - Ensure blank line before `return`
- [ ] 2.6 Edit `packages/transaction/lib/src/application/prepare_hd_send_use_case.dart`:
  - Add `import 'package:address/address.dart';` (alphabetical placement)
  - Rename `e.address` / `entry.address` to `e.value` / `entry.value` at the three access sites (map key building, addressStrings map, changeAddress `.first.address`)
  - Leave `entry.index`, `entry.type`, and all `u.address` (ScannedUtxo field) accesses unchanged
- [ ] 2.7 Edit `packages/transaction/lib/transaction.dart`: remove `export 'src/domain/value_object/hd_address_entry.dart';`
- [ ] 2.8 Delete `packages/transaction/lib/src/domain/value_object/hd_address_entry.dart`

### Batch 3 — checks + security gate

- [x] 2.9 Run `flutter analyze --fatal-infos --fatal-warnings` — exit 0
- [x] 2.10 Run `flutter test` — exit 0; count not lower than baseline (21 tests)
- [x] 2.11 Run `flutter test packages/keys/test/` — all BW-0003 reference vectors green (36 tests)
- [x] 2.12 Run `grep -rn "HdAddressEntry" packages/ lib/ test/` — zero rows
- [x] 2.13 Run `test ! -e packages/transaction/lib/src/domain/value_object/hd_address_entry.dart` — succeeds (DELETED)
- [x] 2.14 Run `grep -n "derivationPath" packages/transaction/ lib/core/adapters/` — zero new read sites (pre-existing Utxo field declaration only)
- [x] 2.15 Run `/aidd-run-checks` — exit 0 (format + analyze + test all green)
- [x] 2.16 Author `docs/BW-0005/security/phase-2-security.md` covering: key-material boundary, `derivationPath` not newly read, no new telemetry/logging surface, signing call sites unchanged
- [x] 2.17 Update `docs/BW-0005/tasklist-BW-0005.md` Phase 2 row to `🟨 In Progress (Batch 3 done, pending reviewer gate)`

---

## Stop Conditions

- architecture deviation
- blocker (e.g. unexpected cycle found by `dart pub deps`)
- risk discovery (e.g. `derivationPath` found to be read at an unexpected site)
- batch complete

---

## Acceptance

- `grep -rn "HdAddressEntry" packages/ lib/ test/` returns zero rows
- `test ! -e packages/transaction/lib/src/domain/value_object/hd_address_entry.dart` succeeds
- `grep -A2 'address:' packages/transaction/pubspec.yaml` shows `path: ../address`
- `dart pub get` exits 0; `dart pub deps address | grep transaction` returns empty
- `flutter analyze --fatal-infos --fatal-warnings` exits 0
- `flutter test` exits 0; test count not lower than 21
- All BW-0003 reference-vector signing tests green
- `grep -n "derivationPath" packages/transaction/ lib/core/adapters/` shows zero new read sites
- `docs/BW-0005/security/phase-2-security.md` exists and covers all four security checkpoints
- `/aidd-run-checks` exits 0
