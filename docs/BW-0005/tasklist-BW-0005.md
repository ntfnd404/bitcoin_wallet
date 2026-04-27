# Tasklist: BW-0005 — Architecture Refactor + Package Documentation

Status: `TASKLIST_READY`
Ticket: BW-0005
Phase: feature
Lane: Critical
Workflow Version: 3
Owner: Planner
Context: Idea `docs/BW-0005/idea-BW-0005.md` · Vision `docs/BW-0005/vision-BW-0005.md`

---

## Progress

| Phase | Goal | Status | Review | Security | QA |
|-------|------|--------|--------|----------|----|
| 1 | Reorganise `bitcoin_node/lib/src/` into 5 consumer-aligned subfolders | ✅ Done | ✅ | n/a | ✅ |
| 2 | Remove `HdAddressEntry`, add `transaction → address`, use `Address` directly | ✅ Done | ✅ | ✅ | ✅ |
| 3 | HD/Node subfolders in `wallet/`, `transaction/`, `address/` (data + application) | ✅ Done | ✅ | ✅ | ✅ |
| 4 | READMEs for all 9 packages + rewrite `docs/project/architecture.md` | ✅ Done | ✅ | n/a | ✅ |

Legend: ⬜ Pending · 🟦 Planned (plan + brief written, ready to implement) · 🟨 In Progress · ✅ Done

---

## Phase Breakdown

### Phase 1: Reorganise `bitcoin_node` by consumer module

Lane: Professional · Risk: Low
Plan: `docs/BW-0005/plan/BW-0005-phase-1.md` (`PLAN_APPROVED`)
Brief: `docs/BW-0005/phase/BW-0005/phase-1.md` (`TASKLIST_READY`)

- [x] 1.1 Define target subfolders: `wallet/`, `address/`, `transaction/`, `utxo/`, `block/`
- [x] 1.2 Move existing files into the matching subfolder
- [x] 1.3 Update internal `bitcoin_node` imports
- [x] 1.4 Update import paths in all consumers (`packages/*`, `lib/`) — no external consumers of `src/` found; public barrel unchanged
- [x] 1.5 Run `/aidd-run-checks` (format → analyze → test) — all green (21 tests pass; 1 pre-existing info in `address_type_display.dart:22`)

Exit criteria:
- All tests pass
- No file directly under `bitcoin_node/lib/src/` (only the public barrel)

---

### Phase 2: Remove `HdAddressEntry`, use `Address` directly

Lane: Critical · Risk: Medium
Plan: `docs/BW-0005/plan/BW-0005-phase-2.md` (`PLAN_APPROVED`)
Brief: `docs/BW-0005/phase/BW-0005/phase-2.md` (`TASKLIST_READY`)

- [x] 2.1 Add `address: path: ../address` to `transaction/pubspec.yaml` dependencies (alphabetical); run `dart pub get`; verify no cycle
- [x] 2.2 Update `hd_address_data_source.dart`: import `address`, return `List<Address>`
- [x] 2.3 Update `hd_address_data_source_impl.dart`: remove `HdAddressEntry` mapping, return `addresses` directly
- [x] 2.4 Update `prepare_hd_send_use_case.dart`: import `address`, rename `entry.address` → `entry.value` at all three sites
- [x] 2.5 Remove `hd_address_entry.dart` export from `transaction.dart` barrel
- [x] 2.6 Delete `packages/transaction/lib/src/domain/value_object/hd_address_entry.dart`
- [x] 2.7 Run `/aidd-run-checks` and all verification greps
- [x] 2.8 Security-reviewer gate — author `docs/BW-0005/security/phase-2-security.md`

Exit criteria:
- `grep -rn "HdAddressEntry" packages/ lib/ test/` returns no rows
- Reference-vector signing tests (BW-0003) still green
- Security review artifact exists at `docs/BW-0005/security/phase-2-security.md`

---

### Phase 3: HD/Node subfolders by trust model

Lane: Critical · Risk: Medium
Plan: `docs/BW-0005/plan/BW-0005-phase-3.md` (`PLAN_APPROVED`)
Brief: `docs/BW-0005/phase/BW-0005/phase-3.md` (`TASKLIST_READY`)

- [x] 3.1 In `wallet/`: create `application/hd/` and `application/node/`; move 3 use-case files; update barrel + assembly
- [x] 3.2 In `address/`: create `application/hd/` and `application/node/`; move 2 strategy files; update barrel + assembly
- [x] 3.3 In `transaction/`: create `application/hd/` and `application/node/`; move 6 files; update internal imports, barrel, assembly
- [x] 3.4 Relocate wallet use-case tests to mirror new `hd/`/`node/` source paths; fix relative fixture imports
- [x] 3.5 Verify HD code never imports from `node/` and vice versa within each package (6 greps return zero rows)
- [x] 3.6 Run `/aidd-run-checks` (full suite green; test count not lower than baseline)
- [x] 3.7 Security-reviewer gate — author `docs/BW-0005/security/phase-3-security.md`

Exit criteria:
- `application/hd/` and `application/node/` present in all three packages
- All six cross-trust greps return zero rows
- `flutter analyze --fatal-infos --fatal-warnings` exits 0
- `flutter test` green; BW-0003 reference vectors bit-identical
- Security review artifact at `docs/BW-0005/security/phase-3-security.md`

---

### Phase 4: Package READMEs + rewrite `architecture.md`

Lane: Professional · Risk: Low
Plan: `docs/BW-0005/plan/BW-0005-phase-4.md` (`PLAN_APPROVED`)
Brief: `docs/BW-0005/phase/BW-0005/phase-4.md` (`TASKLIST_READY`)

- [x] 4.1 Author `packages/shared_kernel/README.md`
- [x] 4.2 Author `packages/rpc_client/README.md`
- [x] 4.3 Author `packages/keys/README.md`
- [x] 4.4 Author `packages/storage/README.md`
- [x] 4.5 Author `packages/wallet/README.md`
- [x] 4.6 Author `packages/address/README.md`
- [x] 4.7 Author `packages/transaction/README.md`
- [x] 4.8 Author `packages/bitcoin_node/README.md`
- [x] 4.9 Author `packages/ui_kit/README.md`
- [x] 4.10 Verify: `ls packages/*/README.md | wc -l` returns 9
- [x] 4.11 Rewrite `docs/project/architecture.md` (all seven change areas per plan)
- [x] 4.12 Verify architecture.md: grep + manual diffs pass
- [x] 4.13 Update `docs/project/conventions.md` (README-touch rule + dependency graph block)
- [x] 4.14 Run `/aidd-run-checks` — green
- [x] 4.15 Verify: `grep -n "README" docs/project/conventions.md` non-empty
- [x] 4.16 Update `docs/BW-0005/tasklist-BW-0005.md` Phase 4 row to Done

Exit criteria:
- All 9 packages have a README with the five required sections
- Architecture document matches the real package layout (nine packages, post-Phase-1/3 trees)
- `conventions.md` carries the README-touch process rule

---

## Release Readiness

- [x] All phases complete
- [x] All review summaries present
- [x] All `Critical` phases have security review artifacts
- [x] All QA records passed
- [x] Validator clean
- [x] Persistent docs updated (`architecture.md`, `conventions.md`, package READMEs)
