Status: REVIEW_OK
Ticket: BW-0003
Phase: 1
Lane: Critical
Workflow Version: 3
Owner: reviewer

---

## Blocking Findings

### 1 — BlocProvider.value anti-pattern in WalletDetailScreen

**File:** `lib/feature/wallet/view/screen/detail/wallet_detail_screen.dart:54`

Screen creates AddressBloc in `didChangeDependencies`, stores it in `late final _addressBloc`,
manually closes in `dispose`, then injects via `BlocProvider<AddressBloc>.value`. Hard rule violation.
Fix: use `BlocProvider(create: (ctx) => AddressScope.newAddressBloc(ctx))` — let the provider own lifecycle.

### 2 — Null assertions `!` in new code (5 violations)

**`lib/feature/signing/manual_utxo/view/screen/signing_demo_screen.dart`:**
- Line ~148: `utxo.address!` — replace with local variable
- Line ~176: `formKey.currentState!.validate()` — null-check required
- Line ~263: `state.txid!` — extract to local variable
- Line ~269: `state.broadcastedTx!.confirmations` — extract to local variable

**`packages/keys/lib/src/data/crypto/bech32.dart:13`:**
- `_convertBits(...)!` — crypto code, Critical lane. Change return type or null-check.

### 3 — Missing `isClosed` guards in XpubBloc

**File:** `lib/feature/signing/xpub/bloc/xpub_bloc.dart`

`await _getXpub(...)` called inside loop with no `isClosed` check before subsequent `emit()`.
If BLoC closes during the loop, emit throws. SigningBloc correctly guards — XpubBloc must too.

---

## Observations (for security reviewer)

### A — Non-standard k derivation (not full RFC 6979)

**File:** `packages/keys/lib/src/data/crypto/ecdsa.dart`

k is seeded from sha256(privateKey ‖ sighash) via Fortuna PRNG — deterministic but not HMAC-DRBG.
Prevents k-reuse. Low-S normalization applied (BIP62). Acceptable for regtest-only scope.
Must be documented as known limitation in security review.

### B — Private keys not zeroed after signing

**File:** `packages/keys/lib/src/application/sign_transaction_use_case.dart`

`SigningInput.privateKey` (Uint8List) not zeroed after use. Dart GC is responsible.
Acceptable for regtest-only. Must be documented as known limitation.

---

## Architecture Compliance

| Rule | Status |
|------|--------|
| DDD/SOLID layer boundaries | PASS |
| BLoC only (never Cubit) | PASS |
| Each BLoC in own sub-folder | PASS |
| Never BlocProvider.value | FAIL — wallet_detail_screen.dart |
| Never pass BLoC as constructor param | PASS |
| Strategy over switch | PASS |
| Namespace grouper pattern (zero Dart files) | PASS |
| `isClosed` before emit after await | FAIL — XpubBloc |
| No `!` null assertions | FAIL — 5 violations |

---

## Fixes Applied

1. `WalletDetailScreen` — converted to `StatelessWidget`, `BlocProvider(create:)` owns lifecycle
2. `bech32.dart` — `!` replaced with explicit null check + `StateError`
3. `XpubBloc` — `isClosed` guards added after every `await`
4. `signing_demo_screen.dart` — all 4 `!` assertions removed

All checks after fix: `flutter analyze` clean, `dcm analyze` clean, 13+36 tests passed.

## Verdict

REVIEW_OK. Proceed to security-reviewer (Critical lane).
