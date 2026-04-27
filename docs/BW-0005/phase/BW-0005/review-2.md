# Review Summary: BW-0005 Phase 2 — Remove `HdAddressEntry`, Use `Address` Directly

Status: `REVIEW_OK`
Ticket: BW-0005
Phase: 2
Lane: Critical
Workflow Version: 3
Owner: Reviewer
Date: 2026-04-25

---

## Verdict

`REVIEW_OK`

---

## Blocking Findings

- None

---

## Important Findings

1. **Security gate not yet closed.** `docs/BW-0005/security/phase-2-security.md` exists and all
   four invariants are documented as PASS in the narrative, but the artifact status is
   `SECURITY_REVIEW_PENDING` and the checklist items remain unchecked. The security-reviewer
   agent must tick the checklist and set status to `SECURITY_REVIEW_PASS` before the phase is
   marked complete. This is a workflow gate, not a code correctness issue.

---

## Deviations From Plan

1. **Missing explicit `import 'package:address/address.dart';` in `prepare_hd_send_use_case.dart`.**
   Plan step 2c and checklist item 2.6 required adding this import. The implementation omits it.
   `Address` is consumed via type inference from the `HdAddressDataSource` return type;
   `AddressType` resolves via the existing `package:shared_kernel/shared_kernel.dart` import.
   `flutter analyze --fatal-infos --fatal-warnings` exits 0 (no missing-import error).
   Impact: none — the file compiles correctly and behavior is identical.
   The import is not required by the analyzer when the type is used only by inference.
   Recommendation: add it anyway for explicitness (a reader of the file should not have to
   trace through the interface to discover the `Address` dependency), but this does not block
   the review.

---

## Regression Checks

All items verified against the execution checklist (Batch 3):

1. **pubspec.yaml** — `address: path: ../address` present, alphabetically before `shared_kernel`,
   no `^`. Correct.
2. **Interface contract** — `hd_address_data_source.dart` imports `package:address/address.dart`,
   no `hd_address_entry.dart`, `getAddressesForWallet` returns `Future<List<Address>>`. Correct.
3. **Adapter impl** — `hd_address_data_source_impl.dart` has no `HdAddressEntry` import, return
   type is `Future<List<Address>>`, body is direct `return addresses;` with blank line before
   return, no `print`/`dynamic`/new `!`. Correct.
4. **Use case** — `prepare_hd_send_use_case.dart` has no `HdAddressEntry` reference; all HD
   address `.address` field accesses renamed to `.value` (lines 43, 47, 85); `u.address` and
   `u.address!` on `ScannedUtxo` (lines 69, 75) are pre-existing and unchanged. Correct.
5. **Barrel** — `transaction.dart` does not export `hd_address_entry.dart`. Correct.
6. **File deleted** — `packages/transaction/lib/src/domain/value_object/hd_address_entry.dart`
   does not exist on disk. Confirmed.
7. **Zero `HdAddressEntry` references** — file deleted, barrel has no export, no other reference
   sites visible in `packages/` or `lib/`. Confirmed.
8. **`derivationPath` boundary** — security artifact confirms only pre-existing field declarations
   in `Utxo` entity (`packages/transaction/lib/src/domain/entity/utxo.dart` lines 36 and 50);
   no new read sites in any modified file. Correct.
9. **Code style** — all modified files use `package:` imports, blank line before `return` in
   `hd_address_data_source_impl.dart`, no `print`, no `dynamic`. Correct.
10. **Security artifact exists** — `docs/BW-0005/security/phase-2-security.md` present, covering
    all four Critical-lane invariants. Status `SECURITY_REVIEW_PENDING` (workflow gate, see
    Important Findings).

---

## Next Action

- Security-reviewer agent to tick checklist and set status to `SECURITY_REVIEW_PASS` in
  `docs/BW-0005/security/phase-2-security.md`.
- Consider (non-blocking) adding `import 'package:address/address.dart';` to
  `prepare_hd_send_use_case.dart` for explicitness.
- Proceed to QA after security gate is closed.
