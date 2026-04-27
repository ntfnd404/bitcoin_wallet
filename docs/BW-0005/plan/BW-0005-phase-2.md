# Plan: BW-0005 Phase 2 — Remove `HdAddressEntry`, Use `Address` Directly

Status: `PLAN_APPROVED`
Ticket: BW-0005
Phase: 2
Lane: Critical
Workflow Version: 3
Owner: Planner / Architect

---

## Phase Scope

Remove the `HdAddressEntry` value object from the `transaction` package, declare an explicit
`transaction → address` path dependency, and route every reference site through the canonical
`Address` entity from `packages/address`. Behaviour must remain bit-identical. The only change
observable from outside the package is that `HdAddressDataSource.getAddressesForWallet` returns
`List<Address>` instead of `List<HdAddressEntry>`.

No new logic is introduced. No test scenarios are removed. No new dependency edge is added other
than `transaction → address`.

---

## File Changes

| File | Change | Why |
|------|--------|-----|
| `packages/transaction/pubspec.yaml` | Add `address: path: ../address` under `dependencies`, placed alphabetically between the top-level `a` slot and `shared_kernel` | Declares the explicit package dependency required to import `Address` |
| `packages/transaction/lib/src/domain/data_sources/hd_address_data_source.dart` | Replace `import` of `hd_address_entry.dart` with `package:address/address.dart`; change return type of `getAddressesForWallet` from `Future<List<HdAddressEntry>>` to `Future<List<Address>>` | Contract change: consumer interface now names the canonical type |
| `packages/transaction/lib/src/application/prepare_hd_send_use_case.dart` | Add `import 'package:address/address.dart';`; rename all `entry.address` reads to `entry.value`; preserve all `entry.index` and `entry.type` accesses unchanged; update `addressLookup` key and the `changeAddress` access from `e.address` to `e.value` | Field rename from `HdAddressEntry.address` to `Address.value`; all other fields survive unchanged |
| `lib/core/adapters/hd_address_data_source_impl.dart` | Remove the `.map((a) => HdAddressEntry(...)).toList()` conversion; return `addresses` directly from `_repository.getAddresses(walletId)`; change the return type annotation to `Future<List<Address>>`; remove the `HdAddressEntry` import (the `address` import is already present) | Impl no longer needs to copy fields into a local type |
| `packages/transaction/lib/transaction.dart` | Remove the line `export 'src/domain/value_object/hd_address_entry.dart';` | The value object is deleted; the barrel must not export a non-existent file |
| `packages/transaction/lib/src/domain/value_object/hd_address_entry.dart` | **Delete** the file | Canonical type is `Address`; the duplicate is removed |
| `docs/BW-0005/security/phase-2-security.md` | **Create** security-reviewer artifact | Critical-lane gate requirement |

---

## Interfaces And Contracts

```dart
// BEFORE (packages/transaction/lib/src/domain/data_sources/hd_address_data_source.dart)
import 'package:transaction/src/domain/value_object/hd_address_entry.dart';

abstract interface class HdAddressDataSource {
  Future<List<HdAddressEntry>> getAddressesForWallet(String walletId);
}

// AFTER
import 'package:address/address.dart';

abstract interface class HdAddressDataSource {
  /// Returns all stored addresses for [walletId] with their derivation metadata.
  Future<List<Address>> getAddressesForWallet(String walletId);
}
```

```dart
// AFTER — hd_address_data_source_impl.dart (simplified body)
@override
Future<List<Address>> getAddressesForWallet(String walletId) async {
  final addresses = await _repository.getAddresses(walletId);

  return addresses;
}
```

```dart
// Key rename in prepare_hd_send_use_case.dart — field accesses that must change:
// entry.address  →  entry.value   (lines 43, 47, 85 in the current file)
// All other field accesses (entry.index, entry.type) are unchanged.

// addressLookup type changes implicitly:
// BEFORE: Map<String, HdAddressEntry>
// AFTER:  Map<String, Address>
// Key is always entry.value (the address string); lookup semantics are unchanged.

// changeAddress derivation:
// BEFORE: .first.address
// AFTER:  .first.value
```

---

## Sequencing

### Batch 1 — Dependency declaration (pubspec only)

1. Edit `packages/transaction/pubspec.yaml`: add `address: path: ../address` in the `dependencies`
   block, placed before `shared_kernel` (alphabetical order). No `^`; no version number (workspace
   path dependency).
2. Run `dart pub get` from the workspace root. Verify exit 0.
3. Run `dart pub deps` for the `address` package and confirm no cycle back to `transaction`.

Rationale: isolating the pubspec change as Batch 1 lets the resolver fail early before any source
edit is attempted.

### Batch 2 — Source changes (five files)

Execute in this order to keep the project compilable at each intermediate step:

2a. Edit `packages/transaction/lib/src/domain/data_sources/hd_address_data_source.dart`:
    - Replace `import 'package:transaction/src/domain/value_object/hd_address_entry.dart';`
      with `import 'package:address/address.dart';`
    - Change return type to `Future<List<Address>>`.

2b. Edit `lib/core/adapters/hd_address_data_source_impl.dart`:
    - Remove `HdAddressEntry` import (no longer needed; `address` import already present).
    - Change return type annotation to `Future<List<Address>>`.
    - Replace the `.map((a) => HdAddressEntry(...)).toList()` body with `return addresses;`.
    - Ensure a blank line before `return` per code-style-guide.

2c. Edit `packages/transaction/lib/src/application/prepare_hd_send_use_case.dart`:
    - Add `import 'package:address/address.dart';` (already imports `shared_kernel` and
      internal transaction types; place alphabetically).
    - Rename every `e.address` / `entry.address` access to `e.value` / `entry.value`.
      Concrete lines to update (from current file):
        - Line 43: `nativeSegwit.map((e) => e.address)` → `e.value`
        - Line 47: `for (final e in nativeSegwit) e.address: e` → `e.value: e`
        - Line 85: `(nativeSegwit..sort(...)).first.address` → `.first.value`
    - All `entry.index` and `entry.type` accesses remain unchanged.
    - No removal of logic; no change to `SigningInput` constructor arguments other than
      `address: u.address!` which is a `ScannedUtxo` field, not an `HdAddressEntry` field —
      verify this is unchanged.
    - Update the local `addressLookup` type comment if one exists; no runtime change.

2d. Edit `packages/transaction/lib/transaction.dart`:
    - Remove the line `export 'src/domain/value_object/hd_address_entry.dart';`.

2e. Delete `packages/transaction/lib/src/domain/value_object/hd_address_entry.dart`.

### Batch 3 — Verification and security artifact

3a. Run `flutter analyze --fatal-infos --fatal-warnings`. Must exit 0.
3b. Run `flutter test`. Must exit 0; test count must not be lower than the pre-phase baseline
    (21 passing tests confirmed in Phase 1 QA).
3c. Run `flutter test packages/keys/test/` specifically to confirm all BW-0003 reference vectors
    pass with bit-identical results.
3d. Run `grep -rn "HdAddressEntry" packages/ lib/ test/` — must return zero rows.
3e. Run `test ! -e packages/transaction/lib/src/domain/value_object/hd_address_entry.dart` — must
    succeed.
3f. Run `grep -n "derivationPath" packages/transaction/ lib/core/adapters/` — must show no new
    read site (any result must pre-date this phase or appear only in comments).
3g. Run `/aidd-run-checks`.
3h. Author `docs/BW-0005/security/phase-2-security.md` (see security section below).

---

## Error Handling And Edge Cases

- **Field rename silent failure.** `entry.address` and `entry.value` are both `String`; the Dart
  analyzer will catch any missed rename as a compile-time "undefined getter" error because
  `HdAddressEntry` is deleted. No silent semantic drift is possible once the file is removed.

- **`u.address!` in `prepare_hd_send_use_case.dart` line 75.** This reads from `ScannedUtxo`,
  not from `HdAddressEntry`. It must remain unchanged. The `conventions.md` rule "never use `!`"
  applies to new code written in this phase — do not alter existing `!` uses unless they are in
  lines being edited for the rename. If a line being edited for another reason contains `!`, surface
  it as a blocker rather than silently leaving it.

- **`AddressType` import.** After removing the `HdAddressEntry` import from
  `hd_address_data_source.dart`, verify that `AddressType` is still accessible via
  `package:address/address.dart` (it is — `address` re-exports `shared_kernel` transitively
  through its own domain types). If the analyzer reports a missing `AddressType` symbol, add
  an explicit `import 'package:shared_kernel/shared_kernel.dart';` to that file.

- **Workspace resolution after pubspec edit.** `dart pub get` must be run before any source edit
  that imports `package:address/address.dart` from within `transaction`; otherwise the analyzer
  will report unresolved package errors.

- **`transaction_assembly.dart` — no edit required.** Research confirmed that
  `packages/transaction/lib/transaction_assembly.dart` declares `HdAddressDataSource` as an
  interface type (not `HdAddressEntry`); only the method's generic parameter changes. Because Dart
  resolves the concrete type via the interface, the assembly file requires no change. Verify this
  by running `dart analyze` and confirming no error in that file.

- **`app_dependencies_builder.dart` — no edit required.** The DI registration passes
  `HdAddressDataSourceImpl(repository: address.addressRepository)` which does not reference
  `HdAddressEntry`. Verify by running `dart analyze`.

---

## Security Trust Boundary — Critical Lane Analysis

### What this phase changes at the boundary

Before Phase 2 the trust boundary between `transaction` and `address` was implicit: `transaction`
held a local mirror (`HdAddressEntry`) of three fields from `Address`, preventing the package from
seeing any `Address`-specific fields that were not explicitly mirrored.

After Phase 2, `transaction` can import any field of `Address`, including `derivationPath`. This
widens the **accessible** surface of HD metadata inside `transaction`; it does not widen the
**used** surface unless a developer explicitly reads `derivationPath`.

### Security review gate requirements

The security-reviewer artifact (`docs/BW-0005/security/phase-2-security.md`) must confirm all
four of the following:

1. **Key material boundary unchanged.** Private keys, WIFs, seed bytes remain inside
   `packages/keys/`. `Address` carries no key material. No modified file gains the ability to
   sign or access key material.

2. **`derivationPath` not newly read.** After the change, `grep -n "derivationPath"` in
   `packages/transaction/` and `lib/core/adapters/` must show zero new read sites. The field may
   appear in the `Address` class definition (inside `packages/address/`) but no
   `transaction`-package or adapter code may read it. `PrepareHdSendUseCase` and
   `HdAddressDataSourceImpl` use only `Address.value`, `Address.index`, and `Address.type` — the
   same three fields that `HdAddressEntry` exposed.

3. **No new telemetry or logging surface.** No `developer.log`, `print`, error-message
   interpolation, or exception-message string in the modified files may reference
   `derivationPath`, `index`, or any other HD metadata. Existing log sites are unchanged.

4. **Signing call sites unchanged.** `PrepareHdSendUseCase` constructs `SigningInput` with
   `derivationIndex: entry.index` and `addressType: entry.type` — semantically identical to before.
   `HdTransactionSigner` and `keys/SignTransactionUseCase` are not touched. The reference-vector
   signing tests provide automated proof.

### `derivationPath` exposure invariant

`Address.derivationPath` is HD linkability metadata (non-secret but sensitive). The invariant after
Phase 2: only `HdAddressGenerationStrategy` (inside `packages/address/`) writes it; no code outside
`packages/address/` or `packages/keys/` reads it. This must be verified by grep and documented in
the security artifact.

---

## Checks

```
# After Batch 1
dart pub get                                            # workspace root; must exit 0
dart pub deps address | grep transaction               # must return empty — no cycle

# After Batch 2 + 3
flutter analyze --fatal-infos --fatal-warnings         # exit 0; zero warnings/infos
flutter test                                           # exit 0; test count >= 21
flutter test packages/keys/test/                       # all BW-0003 reference vectors green
grep -rn "HdAddressEntry" packages/ lib/ test/         # zero rows
test ! -e packages/transaction/lib/src/domain/value_object/hd_address_entry.dart
grep -A2 'address:' packages/transaction/pubspec.yaml  # shows path: ../address
grep -n "derivationPath" packages/transaction/ lib/core/adapters/  # zero new read sites
/aidd-run-checks                                       # exit 0
```

---

## Risks

- **Silent `e.address` → `e.value` miss.** Mitigated by the file deletion: once
  `hd_address_entry.dart` is deleted, any surviving `HdAddressEntry` reference causes a compile
  error. The grep check in Batch 3 is a belt-and-suspenders confirmation.

- **`AddressType` resolution inside `transaction`.** `AddressType` is currently imported via
  `shared_kernel` from within `hd_address_entry.dart`. After deletion, the data-source file must
  still resolve `AddressType`. The `address` barrel re-exports it transitively. If not, add an
  explicit `shared_kernel` import. Mitigated by running `flutter analyze` before committing.

- **`derivationPath` accidental read.** The field is now visible inside `transaction`; a future
  developer might reach for it. This phase must not read it; the security review enforces this.
  Long-term mitigation is Phase 3's HD/Node subfolder boundary.

- **Test count regression.** Research confirms zero tests reference `HdAddressEntry` directly,
  so no test rewrite is required and count cannot drop due to this change. The only test update
  risk is if the existing `prepare_hd_send_use_case` code path is covered by an integration test
  using a real `HdAddressDataSourceImpl` — none found in the research. Mitigated by `flutter test`
  baseline comparison.
