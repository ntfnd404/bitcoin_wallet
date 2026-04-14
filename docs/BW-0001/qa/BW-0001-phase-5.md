# QA: BW-0001 Phase 5 — BLoC

Status: `QA_PASS`
Ticket: BW-0001
Phase: 5
Lane: Professional
Workflow Version: 3
Owner: QA
Date: 2026-04-05

---

## Scope

Covers `WalletBloc`, `AddressBloc`, and `WalletScope` delivered in Phase 5.
Verifies all acceptance criteria from `phase-5.md`, the PRD scenarios, and the
two post-review fixes (F-1 and F-2 from `BW-0001-phase-5-summary.md`).

Out of scope: UI screens (Phase 6), navigator wiring (Phase 7), unit test
execution (optional per PRD).

---

## Positive Scenarios (PS)

- [x] PS-1: `HdWalletCreateRequested` → `WalletBloc` emits `creating` then
  `awaitingSeedConfirmation` with `pendingMnemonic` non-null and `pendingWallet`
  non-null.
  `_onHdWalletCreateRequested` emits `creating` at line 71, then on success
  emits `awaitingSeedConfirmation` with `pendingWallet: wallet,
  pendingMnemonic: mnemonic` at lines 78-82.

- [x] PS-2: `SeedConfirmed` → `WalletBloc` emits `loaded` with
  `pendingMnemonic == null` and `pendingWallet == null`.
  `_onSeedConfirmed` (lines 115-128) emits `loaded` with
  `clearPendingWallet: true, clearPendingMnemonic: true`.

- [x] PS-3: `NodeWalletCreateRequested` → `WalletBloc` emits `creating` then
  `loaded` with the new wallet appended.
  `_onNodeWalletCreateRequested` (lines 49-65) follows this exact path.

- [x] PS-4: `WalletListRequested` → `WalletBloc` emits `loading` then `loaded`
  with wallets from both repositories merged via `Future.wait`.
  `_onWalletListRequested` (lines 27-47) uses `Future.wait` and concatenates
  `results[0]` and `results[1]`.

- [x] PS-5: `AddressListRequested` → `AddressBloc` emits `loading` then
  `loaded` with address list from repository.
  `_onAddressListRequested` (lines 16-29) follows this path.

- [x] PS-6: `AddressGenerateRequested` → `AddressBloc` emits `generating` then
  `loaded` with `lastGenerated` populated.
  `_onAddressGenerateRequested` (lines 31-49) emits `generating`, then on
  success emits `loaded` with `lastGenerated: address` and the address appended
  to `addresses`.

- [x] PS-7: `SeedViewRequested` for an existing seed → `WalletBloc` emits
  `awaitingSeedConfirmation` with `pendingMnemonic` non-null.
  `_onSeedViewRequested` (lines 130-153) calls `seedRepository.getSeed` and on
  non-null result emits `awaitingSeedConfirmation` with `pendingMnemonic`.

---

## Negative / Edge Scenarios (NE)

- [x] NE-1: Repository throws during `HdWalletCreateRequested` → `WalletBloc`
  emits `error` with non-null `errorMessage`; `pendingWallet` and
  `pendingMnemonic` are cleared.
  Catch block (lines 83-91) emits `status: WalletStatus.error,
  errorMessage: e.toString(), clearPendingWallet: true,
  clearPendingMnemonic: true`. F-1 fix confirmed present.

- [x] NE-2: Repository throws during `NodeWalletCreateRequested` →
  `WalletBloc` emits `error` with non-null `errorMessage`.
  Catch block at lines 61-64 confirmed.

- [x] NE-3: Second `AddressGenerateRequested` while `status == generating` →
  event is ignored, no emit occurs.
  Guard at line 35: `if (state.status == AddressStatus.generating) return;`.

- [x] NE-4: `SeedViewRequested` for a wallet with no stored seed → `WalletBloc`
  emits `error` with message `'Seed not found for wallet <walletId>'`.
  Lines 137-143: null check on `mnemonic` emits `error` with the exact message
  `'Seed not found for wallet ${event.walletId}'`.

- [x] NE-5: `SeedConfirmed` when `pendingWallet == null` → handler returns
  early without emitting.
  Line 120: `if (confirmed == null) return;` guards early exit.

- [x] NE-6: `emit()` called after `close()` is guarded in all async handlers.
  `isClosed` is checked after every `await` before each subsequent `emit()` in
  all six `WalletBloc` handlers and both `AddressBloc` handlers.

---

## Manual Checks (MC)

- [x] MC-1: `HdWalletCreateRequested` state transition traced through
  `_onHdWalletCreateRequested` — `creating` → `awaitingSeedConfirmation` with
  `pendingMnemonic` non-null. Verified by static code inspection of lines 71-92.

- [x] MC-2: `SeedConfirmed` clears `pendingMnemonic` to null. Verified by
  inspection of lines 115-128: `clearPendingMnemonic: true` is present.

- [x] MC-3: `AddressGenerateRequested` populates `lastGenerated`. Verified by
  inspection of lines 40-44: `lastGenerated: address`. The `derivationPath`
  field on `Address` is populated by the repository; `AddressBloc` passes the
  returned `Address` through unchanged.

- [x] MC-4: `WalletScope.of(context)` does not use null assertion and throws
  `StateError` when `WalletScope` is absent. Verified by inspection of
  `wallet_scope.dart` lines 46-53.

---

## Implementation Verification (IV)

- [x] IV-1: `flutter analyze --fatal-infos --fatal-warnings` — zero issues.
  Confirmed by reviewer (`REVIEW_OK`) and phase checklist (`5.X` checked).

- [x] IV-2: No null assertions (`!`) used anywhere in the seven delivered files.
  Confirmed by full file inspection.

- [x] IV-3: No `dynamic` types used. Confirmed by full file inspection.

- [x] IV-4: No relative imports — all imports use `package:` scheme. Confirmed
  across all seven files.

- [x] IV-5: `final class` used for `WalletBloc`, `AddressBloc`, `WalletState`,
  `AddressState`, `WalletScopeBlocFactory`, and all event subclasses.
  `sealed class` used for `WalletEvent` and `AddressEvent`. Confirmed.

- [x] IV-6: All event class names are past-tense imperative:
  `WalletListRequested`, `NodeWalletCreateRequested`, `HdWalletCreateRequested`,
  `WalletRestoreRequested`, `SeedConfirmed`, `SeedViewRequested`,
  `AddressListRequested`, `AddressGenerateRequested`. Confirmed.

- [x] IV-7: `copyWith` hand-written using bool-flag pattern
  (`clearPendingWallet`, `clearPendingMnemonic`, `clearErrorMessage`,
  `clearLastGenerated`). No code generation. Confirmed.

- [x] IV-8: `WalletStatus` enum values match plan exactly:
  `initial, loading, loaded, creating, awaitingSeedConfirmation, error`.
  `AddressStatus` enum values match plan exactly:
  `initial, loading, loaded, generating, error`. Confirmed.

- [x] IV-9: No mnemonic material appears in logs or error messages.
  `Mnemonic` has no `toString()` — it is stored in state as a value object and
  never interpolated into error strings. `SeedViewRequested` error message
  contains only `event.walletId`, not mnemonic content. Confirmed.

- [x] IV-10: F-1 fix confirmed — `_onHdWalletCreateRequested` catch block
  (lines 83-91) now includes `clearPendingWallet: true, clearPendingMnemonic:
  true`.

- [x] IV-11: F-2 fix confirmed — `_onSeedConfirmed` (line 115) signature is
  `void`, not `async`. No redundant `async` keyword present.

- [x] IV-12: Blank line before `return` where preceding code exists.
  `_onSeedViewRequested` (line 143): blank line before early `return`. 
  `WalletScope.of` (line 52): blank line before `return scope.blocFactory`.
  Confirmed.

- [x] IV-13: `WalletScope.of` uses `dependOnInheritedWidgetOfExactType` (not
  `findAncestorWidgetOfExactType`), enabling correct rebuild subscription.
  Confirmed at `wallet_scope.dart` line 47.

- [x] IV-14: `updateShouldNotify` returns `blocFactory != oldWidget.blocFactory`.
  Confirmed at `wallet_scope.dart` line 56.

- [x] IV-15: BLoC only — no Cubits used anywhere. Confirmed.

- [x] IV-16: All seven files listed in the plan are present and created.
  `wallet_state.dart`, `wallet_event.dart`, `wallet_bloc.dart`,
  `address_state.dart`, `address_event.dart`, `address_bloc.dart`,
  `wallet_scope.dart` — all confirmed by file reads.

---

## Evidence

- `lib/feature/wallet/bloc/wallet_state.dart` — `WalletStatus` enum and
  `WalletState` with bool-flag `copyWith`.
- `lib/feature/wallet/bloc/wallet_event.dart` — sealed hierarchy, six event
  classes, all with `const` constructors.
- `lib/feature/wallet/bloc/wallet_bloc.dart` — six handlers; F-1 fix at lines
  83-91; F-2 fix at line 115 (`void` signature).
- `lib/feature/wallet/bloc/address_state.dart` — `AddressStatus` enum and
  `AddressState` with bool-flag `copyWith`.
- `lib/feature/wallet/bloc/address_event.dart` — sealed hierarchy, two event
  classes.
- `lib/feature/wallet/bloc/address_bloc.dart` — guard at line 35; `isClosed`
  after every `await`.
- `lib/feature/wallet/di/wallet_scope.dart` — `WalletScopeBlocFactory` with
  `const` constructor; `WalletScope.of` with `StateError`, no `!`.
- Reviewer verdict `REVIEW_OK` in `docs/BW-0001/BW-0001-phase-5-summary.md`.
- `flutter analyze` confirmed clean (phase checklist item 5.X marked done).

---

## Verdict

`QA_PASS`

Issues:
- None. Both post-review findings (F-1, F-2) are confirmed fixed in the current
  implementation. All acceptance criteria from `phase-5.md` are satisfied. All
  PRD scenarios are covered. No blocking issues found.
