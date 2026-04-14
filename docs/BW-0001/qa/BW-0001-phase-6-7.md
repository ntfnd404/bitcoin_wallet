# QA: BW-0001 Phase 6 & 7 — UI Screens + Navigation

Status: `QA_READY`
Ticket: BW-0001
Phase: 6, 7
Lane: Professional
Workflow Version: 3
Owner: QA
Date: 2026-04-09

---

## Scope

Covers all Phase 6 screens and Phase 7 wiring.  
Static analysis checks are automated; manual checks require a running macOS build
with Bitcoin Core regtest node (`make start` or `docker compose up`).

Out of scope: unit/widget test execution, QR code rendering, transaction history.

---

## Static Analysis (Automated)

- [x] SA-1: `flutter analyze --fatal-infos --fatal-warnings` → `No issues found`
- [x] SA-2: `dcm analyze lib/` → no output (zero issues)
- [x] SA-3: No `AppScope.of` / `WalletScope.of` calls inside any `view/screen/` file
  — grep returns zero hits
- [x] SA-4: No relative imports in any Phase 6/7 file — all `package:` imports
- [x] SA-5: No `!` null assertion in any Phase 6/7 file
- [x] SA-6: No `print` statements — only `dart:developer` permitted
- [x] SA-7: No `dynamic` usage

---

## Positive Scenarios (PS)

### App Launch

- [ ] PS-1: App launches on macOS without runtime error; `WalletListScreen` shown
  with empty state "No wallets yet"; FAB (➕) visible.
- [ ] PS-2: After restart with existing wallets — wallets reload from repository;
  list populated.

### Node Wallet Flow

- [ ] PS-3: FAB → `CreateWalletScreen`; select "Node Wallet"; enter name; tap Create
  → `WalletDetailScreen` opens (replaces CreateWallet); wallet name in AppBar.
- [ ] PS-4: Back from `WalletDetailScreen` → `WalletListScreen` shows the new Node wallet.
- [ ] PS-5: `WalletDetailScreen` for Node wallet — "View Seed" button **absent**.
- [ ] PS-6: Generate button for each address type (Legacy, Wrapped SegWit, Native SegWit, Taproot)
  → address appears; button re-enabled after generation.
- [ ] PS-7: Tap address → `AddressScreen`; address string shown in full; derivation path
  shows "Managed by Bitcoin Core".
- [ ] PS-8: Tap Copy on `AddressScreen` → SnackBar "Address copied"; paste confirms full address.
- [ ] PS-9: Legacy address starts `m`; Native SegWit starts `bcrt1q`; Taproot starts `bcrt1p`.

### HD Wallet Flow

- [ ] PS-10: FAB → `CreateWalletScreen`; select "HD Wallet"; enter name; tap Create
  → `SeedPhraseScreen` shown with 12 words in a 2-column grid.
- [ ] PS-11: Warning banner visible on `SeedPhraseScreen`; Continue button **disabled** until
  checkbox ticked.
- [ ] PS-12: Tick checkbox → Continue enabled; tap Continue → `WalletListScreen` shown;
  HD wallet visible in list.
- [ ] PS-13: Tap HD wallet → `WalletDetailScreen`; "View Seed" button **visible**.
- [ ] PS-14: Tap "View Seed" → `SeedPhraseScreen` shows same 12 words as during creation.
- [ ] PS-15: Generate address for each type → derivation path shown on `AddressScreen`
  (e.g. `m/44'/1'/0'/0/0`).

### Restore Wallet Flow

- [ ] PS-16: (from CreateWalletScreen or separate entry) → `RestoreWalletScreen`;
  enter known 12-word phrase + name; all words valid → Restore button enabled.
- [ ] PS-17: Tap Restore → `WalletDetailScreen` opens; addresses derived match original wallet.

### Address Screen

- [ ] PS-18: `AddressScreen` shows `[QR]` placeholder text.
- [ ] PS-19: `SelectableText` allows manual selection and copy of address.

---

## Negative / Edge Scenarios (NS)

- [ ] NS-1: `WalletListScreen` with BLoC error → SnackBar with error message shown.
- [ ] NS-2: `CreateWalletScreen` — Create button **disabled** when name field empty.
- [ ] NS-3: `CreateWalletScreen` — Create button **disabled** while `status == creating`
  (spinner shown instead of label).
- [ ] NS-4: `RestoreWalletScreen` — enter invalid BIP39 word → word highlighted red;
  Restore button stays disabled.
- [ ] NS-5: `RestoreWalletScreen` — enter < 12 or > 24 words → "Enter 12 or 24 words" hint;
  Restore stays disabled.
- [ ] NS-6: `WalletDetailScreen` Generate button — second tap while generating is ignored
  (guard in `AddressBloc`).
- [ ] NS-7: `AddressBloc` error → SnackBar shown in `WalletDetailScreen`.

---

## Code Review Checks (CR)

- [x] CR-1: `WalletListScreen`, `CreateWalletScreen`, `SeedPhraseScreen` each wrap with
  `BlocProvider(create: (_) => widget.bloc)` — never `BlocProvider.value`.
- [x] CR-2: `WalletDetailScreen` uses `MultiBlocProvider` for both blocs.
- [x] CR-3: `AppRouter` uses `Navigator.push` / `pushReplacement` / `popUntil` — no named route
  argument decoding.
- [x] CR-4: `_AppState.dispose()` calls `_walletBloc.close()`.
- [x] CR-5: `mounted` guard before `_walletBloc.add(WalletListRequested())` in async callback.
- [x] CR-6: `AppDependenciesBuilder` contains no stub classes.
- [x] CR-7: `HdWalletRepositoryImpl` uses `keyPrefix: 'hd_'`; `NodeWalletRepositoryImpl`
  uses `keyPrefix: 'node_'` — no key collision in `SecureStorage`.
- [x] CR-8: `_onViewSeed` in `AppRouter` uses `addPostFrameCallback` to read
  `pendingMnemonic` after BLoC processes `SeedViewRequested` — no `!` assertion.
- [x] CR-9: BIP39 wordlist contains exactly 2048 words (official trezor/python-mnemonic source).
- [x] CR-10: DCM member ordering: fields before constructor in non-widget classes;
  constructor → static → fields in InheritedWidget classes.

---

## Definition of Done

- [ ] All PS and NS manual checks marked `[x]`
- [ ] HD Wallet: restored wallet generates identical addresses to original
- [ ] Node Wallet: addresses have correct regtest prefix per type
- [ ] Seed phrase survives app restart (flutter_secure_storage)
- [ ] App launches on macOS without crash
- [ ] SA-1 and SA-2 both pass (already verified)
