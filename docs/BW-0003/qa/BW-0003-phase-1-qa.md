# QA: BW-0003 Phase 1 — Key Derivation and Self-Signing

Status: `QA_PASS`
Ticket: BW-0003
Phase: 1
Lane: Critical
Workflow Version: 3
Owner: QA
Date: 2026-04-23

---

## Scope

Covers HD key derivation (BIP32/BIP39), XpubBloc + XpubScreen, SigningBloc + SigningDemoScreen,
TransactionSigningServiceImpl (P2WPKH BIP143), feature folder restructure, and Wallet domain
refactor. Out of scope: mainnet signing, fee calculation, production memory-safety.

---

## Positive Scenarios (PS)

- [x] PS-1 — Xpub display: XpubScreen creates XpubBloc via `BlocProvider(create:)` and dispatches
  `XpubLoadRequested(walletId)`. XpubBloc iterates over all three `AddressType` values, calls
  `_getXpub(walletId, type)` for each, and emits `FetchStatus.loading → FetchStatus.loaded` with
  a `Map<AddressType, AccountXpub>` result. XpubScreen renders xpub string and derivation path for
  each type via `CopyableText` and `DetailSection`. `AddressType` enum covers legacy, p2sh-segwit,
  nativeSegwit — all three rendered.
  Evidence: `xpub_bloc.dart`, `xpub_screen.dart`, `xpub_state.dart`.

- [x] PS-2 — Manual UTXO sign & broadcast state machine: SigningBloc implements the full sequence
  `initial → scanning → scanned → signing → broadcasted`. `UtxoScanRequested` transitions to
  `scanning`, resolves native SegWit addresses, scans UTXOs, emits `scanned`. No UTXOs path emits
  `scanned` with empty list and shows "No UTXOs found" UI. `SignAndBroadcastRequested` transitions to
  `signing`, assembles `SigningInputParam` per UTXO (no raw key material), calls `_signTransaction`,
  broadcasts, verifies, emits `broadcasted` with `txid` and `broadcastedTx`.
  Evidence: `signing_bloc.dart`, `signing_status.dart`, `signing_state.dart`.

- [x] PS-3 — XpubBloc FetchStatus transitions: initial state is `FetchStatus.initial`. On
  `XpubLoadRequested`, first emit is `FetchStatus.loading`. On success, emit is `FetchStatus.loaded`
  with populated `xpubs` map. On exception, emit is `FetchStatus.error` with `errorMessage`.
  Evidence: `xpub_bloc.dart` lines 22, 30, 34.

---

## Negative / Edge Scenarios (NE)

- [x] NE-1 — XpubBloc closed during loop: `isClosed` is checked after every `await _getXpub(...)`.
  If BLoC closes between iterations, handler returns without emitting. Error branch also guards with
  `isClosed` before emitting.
  Evidence: `xpub_bloc.dart` line 27 (`if (isClosed) return;`), line 33 (`if (isClosed) return;`).

- [x] NE-2 — SigningBloc closed during async operations: `isClosed` checked after `_scanUtxos`,
  after `_signTransaction`, and after `_broadcastTransaction.getTransaction`. Both `_onScanRequested`
  and `_onSignAndBroadcast` have guards.
  Evidence: `signing_bloc.dart` lines 65, 69, 125, 129, 137.

- [x] NE-3 — No UTXOs at scan time: when `segwit.isEmpty`, emits `SigningStatus.error` with
  descriptive message and returns early. When scan returns empty list, emits `SigningStatus.scanned`
  with empty `utxos`; UI renders "No UTXOs found" text.
  Evidence: `signing_bloc.dart` lines 50-57, `signing_demo_screen.dart` line 124.

- [x] NE-4 — Sign called without prior scan: `_onSignAndBroadcast` checks `state.utxos.isEmpty`
  and emits error "No UTXOs to spend. Scan first." before any signing attempt.
  Evidence: `signing_bloc.dart` lines 83-90.

- [x] NE-5 — Unresolvable UTXO address index: if `_addressIndexMap` has no entry for a UTXO
  address, `StateError` is thrown and caught by the error handler, emitting `SigningStatus.error`.
  Evidence: `signing_bloc.dart` lines 96-101.

- [x] NE-6 — bech32 bit-conversion failure: `segwitEncode` null-checks the result of
  `_convertBits` and throws `StateError('bech32 encode: bit conversion failed')` — no `!` crash.
  `segwitDecode` returns `null` on any malformed input; callers check for null.
  Evidence: `bech32.dart` lines 13-14.

---

## Manual Checks (MC)

- [ ] MC-1 — Xpub screen: With HD wallet created in regtest, navigate to Account xpubs. Verify
  three sections displayed (Legacy, P2SH-SegWit, Native SegWit), each with xpub and BIP32 path.
  Copy button functional. (Pending regtest run by owner.)

- [ ] MC-2 — Sign & Broadcast demo: With HD wallet and funded native SegWit addresses, navigate to
  Sign & Send (demo). Tap Scan UTXOs — spinner shows during scan, UTXO list appears. Enter valid
  recipient address and amount. Tap Sign & Broadcast — signing spinner, then TXID displayed in green.
  Verify `SigningStatus` progression in debug logs. (Pending regtest run by owner.)

- [ ] MC-3 — Empty UTXO case: With HD wallet with no funded addresses, Scan UTXOs shows
  "No UTXOs found" message and no Send form. (Pending regtest run by owner.)

---

## Implementation Verification (IV)

- [x] IV-1 — `flutter analyze` clean. Confirmed by reviewer (all 4 review fixes applied).
  Evidence: review artifact `docs/BW-0003/review/BW-0003-phase-1-review.md`.

- [x] IV-2 — `dcm analyze` clean. Confirmed by reviewer.
  Evidence: review artifact as above.

- [x] IV-3 — Unit tests: `dart test packages/transaction` 13 passed,
  `dart test packages/keys` 36 passed. Confirmed by reviewer.

- [x] IV-4 — BlocProvider lifecycle — WalletDetailScreen: Screen is a `StatelessWidget`. AddressBloc
  is created via `BlocProvider<AddressBloc>(create: (ctx) => AddressScope.newAddressBloc(ctx)...)`.
  No `BlocProvider.value` call. No manual `close()` in any dispose. Provider owns full lifecycle.
  Evidence: `wallet_detail_screen.dart` lines 21, 30-32.

- [x] IV-5 — Null assertions in signing_demo_screen.dart: Previous violations at lines ~148, ~263,
  ~269 (state fields) resolved — `state.txid ?? ''` used in `_BroadcastResult`, `broadcastedTx`
  accessed via Dart pattern `if (state.broadcastedTx case final tx?)`. Line ~176 retains
  `formKey.currentState!.validate()` but inside the guard `if (formKey.currentState == null || ...)`.
  Short-circuit evaluation ensures `currentState` is non-null when `!` is reached. Safe pattern,
  not a crash-risk violation. All four previously blocking assertions resolved or safely guarded.
  Evidence: `signing_demo_screen.dart` lines 72, 148, 176, 263-270.

- [x] IV-6 — Null assertion in bech32.dart: `_convertBits(...)!` at line 13 replaced with
  explicit null check + `StateError`. No `!` on the crypto call path.
  Evidence: `bech32.dart` lines 13-14.

- [x] IV-7 — Feature folder namespace pattern: zero Dart files exist at
  `lib/feature/signing/*.dart` and `lib/feature/transaction/*.dart`. Both are pure namespace
  grouper folders. Verified by glob search returning no files.

- [x] IV-8 — Sub-feature folder structure:
  - `signing/xpub/`: `bloc/`, `di/`, `view/` present.
  - `signing/manual_utxo/`: `bloc/`, `di/`, `view/` present.
  - `transaction/list/`: `bloc/`, `di/`, `view/` present.
  - `transaction/detail/`: `bloc/`, `di/`, `view/` present.
  Evidence: full file listing from glob.

- [x] IV-9 — Security review artifact present and contains both known limitations:
  Finding 1 (Fortuna PRNG, not RFC 6979) and Finding 2 (private key not zeroed) are explicitly
  documented, risk-assessed, and accepted as regtest-only scope.
  Evidence: `docs/BW-0003/security/BW-0003-phase-1-security.md` Status: `SECURITY_REVIEW_OK`.

- [x] IV-10 — Seed/key logging check: `SigningState` contains only `txid: String?`,
  `broadcastedTx: BroadcastedTx?`, `errorMessage: String?`, `utxos: List<ScannedUtxo>`,
  `status: SigningStatus`. No private key material, no mnemonic, no seed bytes in state or events.
  Error messages use `e.toString()` which produces only `walletId` and structural messages.
  Evidence: `signing_state.dart`, `signing_bloc.dart` line 139, security review Finding 7.

- [x] IV-11 — DI scope insertion: `XpubScope` and `ManualUtxoScope` are both inserted in
  `AppRouterDelegate.build` above the `Navigator`, ensuring scope is available to all routed screens.
  Evidence: `app_router_delegate.dart` lines 28-30.

---

## Evidence

- `lib/feature/signing/xpub/bloc/xpub_bloc.dart` — isClosed guards, FetchStatus transitions
- `lib/feature/signing/xpub/view/screen/xpub_screen.dart` — BlocProvider(create:), all AddressTypes
- `lib/feature/signing/manual_utxo/bloc/signing_bloc.dart` — full state machine, no key material
- `lib/feature/signing/manual_utxo/bloc/signing_status.dart` — enum: initial, scanning, scanned, signing, broadcasted, error
- `lib/feature/signing/manual_utxo/view/screen/signing_demo_screen.dart` — null assertions resolved
- `lib/feature/wallet/view/screen/detail/wallet_detail_screen.dart` — StatelessWidget, BlocProvider(create:)
- `packages/keys/lib/src/data/crypto/bech32.dart` — null-checked convertBits, StateError on failure
- `lib/core/routing/app_router_delegate.dart` — XpubScope + ManualUtxoScope in tree
- `docs/BW-0003/review/BW-0003-phase-1-review.md` — Status: REVIEW_OK, all 4 fixes confirmed applied
- `docs/BW-0003/security/BW-0003-phase-1-security.md` — Status: SECURITY_REVIEW_OK, 10 findings, 2 known limitations documented

---

## Verdict

`QA_PASS`

Issues:
- None blocking. MC-1, MC-2, MC-3 are runtime manual checks pending owner regtest run; they do not block QA_PASS as the implementation is structurally correct and all analysis/unit-test gates passed.
- Note: `formKey.currentState!.validate()` on line 176 of `signing_demo_screen.dart` retains a `!` operator, but it is inside a compound null-guard (`formKey.currentState == null || ...`). Short-circuit evaluation makes this safe. Not a defect.
