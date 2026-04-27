# QA: BW-0005 Phase 2 — Remove `HdAddressEntry`, Use `Address` Directly

Status: `QA_PASS`
Ticket: BW-0005
Phase: 2
Lane: Critical
Workflow Version: 3
Owner: QA
Date: 2026-04-25

---

## Scope

Covers removal of `HdAddressEntry` value object, declaration of `transaction → address` path
dependency, and routing of all `HdAddressDataSource` / `PrepareHdSendUseCase` /
`HdAddressDataSourceImpl` reference sites through `Address`.

Out of scope: HD/Node subfolder split (Phase 3), package READMEs (Phase 4), signing logic changes.

---

## Positive Scenarios (PS)

- [x] PS-1: `HdAddressEntry` fully removed — no matches in `packages/` or `lib/` (Scenario 1)
- [x] PS-2: Source file `hd_address_entry.dart` deleted from working tree (Scenario 2)
- [x] PS-3: `transaction/pubspec.yaml` declares `address: path: ../address`, alphabetically before `shared_kernel`, no `^` (Scenario 3)
- [x] PS-4: Interface `HdAddressDataSource.getAddressesForWallet` returns `Future<List<Address>>`, imports `package:address/address.dart` (Scenario 4)
- [x] PS-5: `HdAddressDataSourceImpl` returns `Future<List<Address>>`, no mapping, blank line before `return` (Scenario 5)
- [x] PS-6: `PrepareHdSendUseCase` uses `e.value` / `entry.value` / `.first.value` for address string; `entry.index` and `entry.type` unchanged; `u.address` / `u.address!` on `ScannedUtxo` pre-existing and untouched (Scenario 6)
- [x] PS-7: Barrel `transaction.dart` does not export `hd_address_entry.dart` (Scenario 7)

---

## Negative / Edge Scenarios (NE)

- [x] NE-1: `derivationPath` — only pre-existing declarations on `Utxo` entity at lines 36 and 50; zero new read sites in `packages/transaction/` or `lib/core/adapters/` (Scenario 8)
- [x] NE-2: No new `!` null assertions introduced in any modified file; existing `u.address!` (line 75 of `prepare_hd_send_use_case.dart`) is pre-existing on `ScannedUtxo` and unchanged
- [x] NE-3: No `HdAddressEntry` import survives in `hd_address_data_source_impl.dart`; `address` import was already present

---

## Manual Checks (MC)

- [x] MC-1: Security gates closed — `docs/BW-0005/security/phase-2-security.md` status is `SECURITY_REVIEW_PASS`; all six checklist items ticked (Scenario 9)
- [x] MC-2: Review verdict — `docs/BW-0005/phase/BW-0005/review-2.md` status is `REVIEW_OK`; no blocking findings

---

## Implementation Verification (IV)

- [x] IV-1: All modified files use `package:`-style imports only — confirmed in `hd_address_data_source.dart`, `hd_address_data_source_impl.dart`, `prepare_hd_send_use_case.dart`, `transaction.dart`
- [x] IV-2: No `print`, no `dynamic`, no new `!` in any modified file
- [x] IV-3: Blank line before `return` present in `hd_address_data_source_impl.dart` (line 16)
- [x] IV-4: `prepare_hd_send_use_case.dart` has no `import 'package:address/address.dart'` (deviation from plan, reviewer-approved — type resolved by inference; `flutter analyze` exits 0)

---

## Scenario Table

| Scenario | Result | Notes |
|----------|--------|-------|
| 1 — `HdAddressEntry` fully removed | Pass | Zero matches across `packages/` and `lib/` |
| 2 — `hd_address_entry.dart` deleted | Pass | File does not exist on disk |
| 3 — pubspec dependency declared | Pass | `address: path: ../address` present, alphabetically correct, no `^` |
| 4 — Interface contract | Pass | Imports `package:address/address.dart`; returns `Future<List<Address>>`; no `HdAddressEntry` |
| 5 — Impl returns Address directly | Pass | Return type `Future<List<Address>>`; no mapping; blank line before `return`; no `HdAddressEntry` import |
| 6 — Use case field renames | Pass | `e.value` / `entry.value` / `.first.value`; `entry.index` and `entry.type` unchanged; `u.address` / `u.address!` untouched |
| 7 — Barrel clean | Pass | `transaction.dart` has no `hd_address_entry.dart` export |
| 8 — `derivationPath` boundary | Pass | Pre-existing `Utxo` field declarations at lines 36 and 50 only; zero new read sites |
| 9 — Security gates closed | Pass | `SECURITY_REVIEW_PASS`; all six invariants documented and ticked |
| 10 — Conventions violations | Pass | `package:` imports, no `print`, no `dynamic`, no new `!`, blank line before `return` |

---

## PRD Exit Criteria

| Criterion | Confirmed |
|-----------|-----------|
| `HdAddressEntry` source file removed | Yes — file does not exist |
| No `HdAddressEntry` references remain | Yes — zero across `packages/` and `lib/` |
| `transaction → address` dependency declared | Yes — `pubspec.yaml` line 11–12 |
| Interface contract updated | Yes — `Future<List<Address>>` |
| Adapter impl updated | Yes — direct `return addresses;` |
| Use-case field renames applied | Yes — all three sites renamed to `.value` |
| Barrel cleaned | Yes — no `hd_address_entry.dart` export |
| `derivationPath` not newly read | Yes — Scenario 8 confirmed |
| Security artifact exists and passes | Yes — `SECURITY_REVIEW_PASS` |
| `REVIEW_OK` present | Yes — `review-2.md` |

---

## Evidence

- `packages/transaction/pubspec.yaml` lines 11–12: `address:\n    path: ../address`
- `packages/transaction/lib/src/domain/data_sources/hd_address_data_source.dart` line 1: `import 'package:address/address.dart';`
- `packages/transaction/lib/src/domain/data_sources/hd_address_data_source.dart` line 9: `Future<List<Address>> getAddressesForWallet(String walletId);`
- `lib/core/adapters/hd_address_data_source_impl.dart` lines 14–17: return type + blank line + direct return
- `packages/transaction/lib/src/application/prepare_hd_send_use_case.dart` lines 43, 47, 85: `e.value` / `.first.value`
- `packages/transaction/lib/transaction.dart`: no `hd_address_entry.dart` export
- `packages/transaction/lib/src/domain/value_object/hd_address_entry.dart`: file not found
- `packages/transaction/lib/src/domain/entity/utxo.dart` lines 36, 50: pre-existing `derivationPath` field declaration
- `docs/BW-0005/security/phase-2-security.md`: `Status: SECURITY_REVIEW_PASS`
- `docs/BW-0005/phase/BW-0005/review-2.md`: `Status: REVIEW_OK`

---

## Verdict

`QA_PASS`

Issues:
- None
