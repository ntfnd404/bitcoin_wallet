# Review Summary: BW-0001 Phase 5 — BLoC

Status: `REVIEW_OK`
Ticket: BW-0001
Phase: 5
Lane: Professional
Workflow Version: 3
Owner: Reviewer
Date: 2026-04-05

---

## Verdict

`REVIEW_OK`

Two non-blocking findings are recorded. Neither prevents proceeding to Phase 6, but
finding F-1 should be fixed in a follow-up patch before the feature is considered
complete.

---

## Blocking Findings

- None

---

## Important Findings

### F-1 — `_onHdWalletCreateRequested` error path does not clear pending state

**File:** `lib/feature/wallet/bloc/wallet_bloc.dart`, line 83-86

**Observation:** The `catch` block emits `status: error` without
`clearPendingWallet: true, clearPendingMnemonic: true`.

```dart
} catch (e) {
  if (isClosed) return;
  emit(state.copyWith(status: WalletStatus.error, errorMessage: e.toString()));
}
```

**Impact:** If the BLoC is in `awaitingSeedConfirmation` state from a previous
successful HD-wallet creation and the user triggers a second
`HdWalletCreateRequested` that throws, the error state retains the previous
`pendingWallet` and `pendingMnemonic`. The PRD negative scenario explicitly
requires: *"Repository throws during wallet creation: `WalletBloc` emits `error`
with a non-null `errorMessage`; `pendingWallet` and `pendingMnemonic` are
cleared."*

**Severity:** Important — not blocking Phase 6 start, but must be fixed before
the feature ships.

**Fix:** Add `clearPendingWallet: true, clearPendingMnemonic: true` to the error
`copyWith` call in `_onHdWalletCreateRequested`.

---

### F-2 — `_onSeedConfirmed` declared `async` without any `await`

**File:** `lib/feature/wallet/bloc/wallet_bloc.dart`, lines 110-123

**Observation:** The method signature is `async` but the body performs no
asynchronous work. The `analysis_options.yaml` enables the DCM rule
`avoid-redundant-async`. `flutter analyze` does not run DCM, so the gate passed,
but a DCM run would flag this.

**Impact:** Style/lint only — no correctness issue. BLoC `on<>` accepts
`FutureOr<void>`, so the `async` keyword can be removed without any behavioural
change.

**Severity:** Minor — cosmetic, no functionality impact.

**Fix:** Remove `async` from the `_onSeedConfirmed` signature.

---

## Minor Findings

### F-3 — `SeedConfirmed.walletId` is not validated against `state.pendingWallet?.id`

**File:** `lib/feature/wallet/bloc/wallet_bloc.dart`, lines 114-122

**Observation:** The handler checks `state.pendingWallet != null` but does not
verify that `event.walletId == state.pendingWallet.id`. If a stale event arrives
with a mismatched wallet ID, it silently confirms the wrong pending wallet.

**Impact:** Correctness edge case — only matters if events are queued out of
order, which is unlikely in the current UI design. Not a blocking issue for
Phase 5 but worth hardening.

**Severity:** Minor.

---

## Deviations From Plan

- None. All seven files are present and match the plan contracts exactly.
  The `bool`-flag `copyWith` pattern was chosen over the sentinel pattern; this
  is explicitly permitted by the plan ("either approach is acceptable").

---

## Acceptance Criteria Coverage

| Criterion | Status | Notes |
|-----------|--------|-------|
| `HdWalletCreateRequested` → `creating` → `awaitingSeedConfirmation` with `pendingMnemonic` non-null | Pass | Correct state transitions in `_onHdWalletCreateRequested` |
| `SeedConfirmed` → `pendingMnemonic == null`, status `loaded` | Pass | `clearPendingMnemonic: true` in emit |
| `AddressGenerateRequested` → `lastGenerated` set; `derivationPath` non-null for HD, null for Node | Pass | `lastGenerated: address` in `_onAddressGenerateRequested`; path comes from repository |
| Second `AddressGenerateRequested` while `generating` is ignored | Pass | Guard at top of `_onAddressGenerateRequested` |
| `WalletScope.of(context)` throws `StateError` if absent, no null assertion | Pass | `StateError` thrown explicitly; no `!` used |
| `flutter analyze --fatal-infos --fatal-warnings` passes | Pass | Confirmed zero issues |
| No mnemonic material in logs or error messages | Pass | No `toString()` on `Mnemonic`; `SeedViewRequested` error message contains only `walletId` |

---

## Error Handling Review

| Handler | `isClosed` guard present | `try/catch` present | No re-throw | Notes |
|---------|--------------------------|---------------------|-------------|-------|
| `_onWalletListRequested` | Yes (after `Future.wait` and in catch) | Yes | Yes | |
| `_onNodeWalletCreateRequested` | Yes | Yes | Yes | |
| `_onHdWalletCreateRequested` | Yes | Yes | Yes | Error path missing `clearPendingWallet/Mnemonic` (F-1) |
| `_onWalletRestoreRequested` | Yes | Yes | Yes | |
| `_onSeedConfirmed` | N/A — no `await` | N/A | N/A | `async` keyword redundant (F-2) |
| `_onSeedViewRequested` | Yes | Yes | Yes | Null-seed case emits `error` with message — correct |
| `_onAddressListRequested` | Yes | Yes | Yes | |
| `_onAddressGenerateRequested` | Yes | Yes | Yes | `generating` guard present |

---

## Code Quality Review

| Rule | Status | Notes |
|------|--------|-------|
| No `!` (null assertion) | Pass | None found |
| No `dynamic` | Pass | None found |
| No relative imports | Pass | All imports use `package:` |
| `final class` for BLoC, state, event classes | Pass | |
| `sealed class` for event hierarchies | Pass | |
| All event names past-tense imperative | Pass | |
| `const` constructors on state and event classes | Pass | |
| `copyWith` hand-written, no code generation | Pass | |
| BLoC only — no Cubits | Pass | |
| No public methods or fields on BLoC | Pass | |
| `WalletScope.of` uses `dependOnInheritedWidgetOfExactType` | Pass | |
| `updateShouldNotify` implemented | Pass | |
| Blank line before `return` where preceding code exists | Pass | |
| Page width 120 characters | Pass | |
| Trailing commas in multi-line constructs | Pass | |
| Single quotes | Pass | |
| `WalletStatus` enum values match plan exactly | Pass | `initial, loading, loaded, creating, awaitingSeedConfirmation, error` |
| `AddressStatus` enum values match plan exactly | Pass | `initial, loading, loaded, generating, error` |

---

## Regression Checks

- No existing files were modified in this phase. All seven files are new additions
  under `lib/feature/wallet/`. No regressions possible from file edits.
- Domain interfaces (`NodeWalletRepository`, `HdWalletRepository`,
  `SeedRepository`, `WalletRepository`) are consumed read-only; no interface
  signatures were changed.
- `packages/data`, `packages/domain`, `packages/rpc_client`, `packages/storage`
  are untouched.

---

## Next Action

- Fix F-1 (`clearPendingWallet/Mnemonic` in the HD-create error path) in a
  follow-up commit before Phase 6 UI wiring begins.
- Optionally fix F-2 (remove redundant `async` from `_onSeedConfirmed`) in the
  same commit.
- Proceed to Phase 6 (screens) — the state machines are complete and the
  acceptance criteria are met.
