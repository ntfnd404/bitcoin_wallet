# BW-0001 Phase 6 PRD — UI Screens

Status: `PRD_READY`
Ticket: BW-0001
Phase: 6
Lane: Professional
Workflow Version: 3
Owner: Analyst

---

## Phase Intent

Deliver all six wallet feature screens as self-contained widgets that bind to
the BLoC layer produced in Phase 5. Each screen receives its BLoC via
`BlocProvider(create: ...)` — no DI access inside screen widgets. Navigation
callbacks are passed as constructor arguments so Phase 7 can wire real routes
without changing screen internals.

---

## Deliverables

1. `lib/feature/wallet/view/screen/wallet_list_screen.dart` — list of all
   wallets with empty state and a FAB that triggers `CreateWalletScreen`.
2. `lib/feature/wallet/view/screen/create_wallet_screen.dart` — wallet type
   selector (Node / HD) and wallet name text field; fires the correct
   `WalletBloc` event on submit.
3. `lib/feature/wallet/view/screen/seed_phrase_screen.dart` — read-only
   12/24-word mnemonic grid, security warning banner, mandatory confirmation
   checkbox, and a Continue button that emits `SeedConfirmed`.
4. `lib/feature/wallet/view/screen/restore_wallet_screen.dart` — multi-line
   seed phrase text input with real-time per-word BIP39 validation feedback
   and a Restore button that fires `WalletRestoreRequested`.
5. `lib/feature/wallet/view/screen/wallet_detail_screen.dart` — address list
   grouped by `AddressType`; a Generate Address button per type; a View Seed
   button visible only for HD wallets.
6. `lib/feature/wallet/view/screen/address_screen.dart` — full address string,
   a Copy button, a `[QR]` text placeholder, and either the derivation path or
   "Managed by Bitcoin Core".
7. Supporting extracted widgets in
   `lib/feature/wallet/view/widget/`:
   - `wallet_card.dart` — single wallet list tile.
   - `seed_word_tile.dart` — indexed word cell used in the mnemonic grid.
   - `address_type_section.dart` — header + address list for one `AddressType`.

---

## Scenarios

### Positive

- User opens the app; `WalletListScreen` fires `WalletListRequested`; while
  loading a `CircularProgressIndicator` is shown; on success wallets render as
  `WalletCard` tiles.
- `WalletListScreen` with zero wallets shows a centred "No wallets yet" message
  and the FAB remains visible.
- User taps FAB, chooses "HD Wallet", enters a name, taps Create; BLoC
  transitions to `awaitingSeedConfirmation`; `SeedPhraseScreen` is opened with
  the mnemonic from `state.pendingMnemonic`.
- User taps FAB, chooses "Node Wallet", enters a name, taps Create; BLoC
  transitions to `loaded`; the `onWalletCreated` callback fires with the
  created wallet.
- `SeedPhraseScreen` disables the Continue button until the confirmation
  checkbox is ticked; ticking it enables the button; tapping fires
  `SeedConfirmed`.
- `RestoreWalletScreen` validates each entered word against the BIP39 wordlist
  in real time; words not in the wordlist are highlighted; the Restore button
  is enabled only when the complete phrase is valid.
- `WalletDetailScreen` lists existing addresses grouped by type; tapping an
  address row fires `onAddressSelected`; tapping Generate fires
  `AddressGenerateRequested` for the chosen type.
- `AddressScreen` shows the address string, a Copy button that writes to the
  clipboard, a `[QR]` placeholder, and either the derivation path or
  "Managed by Bitcoin Core".

### Negative / Edge

- `WalletBloc` emits `status: error`; `WalletListScreen` shows
  `state.errorMessage` in a `SnackBar` via `BlocListener`.
- `AddressBloc` emits `status: error`; `WalletDetailScreen` shows the error in
  a `SnackBar`.
- `SeedPhraseScreen` receives `null` for `pendingMnemonic` (guard case — should
  not happen if navigation is wired correctly); shows an error message instead
  of crashing.
- `RestoreWalletScreen` receives a completely invalid phrase; Restore button
  stays disabled and no event is dispatched.
- While BLoC status is `creating` or `generating`, all action buttons are
  disabled and a `CircularProgressIndicator` replaces the button label.
- Address string too long for one line; use `SelectableText` with word-wrap so
  the full address remains visible and copyable.

---

## Success Metrics

| Criterion | Verification |
|-----------|--------------|
| All six screen files exist and `flutter analyze` reports zero issues | `flutter analyze --fatal-infos --fatal-warnings` exits 0 |
| Each screen is a `StatelessWidget` or `StatefulWidget`; no direct DI (`AppScope.of` / `WalletScope.of`) inside screen files | Code review: grep for `AppScope.of` and `WalletScope.of` in `view/screen/` — zero hits |
| `WalletListScreen` shows empty state when `state.wallets` is empty | Visual inspection; widget state: `status: loaded, wallets: []` |
| `SeedPhraseScreen` Continue button is disabled when checkbox is unchecked | Widget test or manual interaction |
| `RestoreWalletScreen` Restore button is disabled when any word fails BIP39 check | Manual: enter an invalid word; button stays disabled |
| Copying an address places the value on the system clipboard | Manual: tap Copy; paste elsewhere |
| Derivation path shown for HD addresses; "Managed by Bitcoin Core" for Node addresses | Manual: open `AddressScreen` for each wallet type |
| No mnemonic or private key material logged or exposed via `print` or `toString` | Code review |

---

## Constraints

- No navigation wiring in this phase — screens accept `VoidCallback` or typed
  callbacks for navigation triggers; Phase 7 owns `AppRouter` and route wiring.
- Screens receive BLoC instances via `BlocProvider(create: ...)` only — never
  `BlocProvider.value` and never constructed directly inside `build`.
- No external QR packages — use `Text('[QR]')` as a placeholder.
- No third-party state management beyond `flutter_bloc`.
- All imports: `package:` only — no relative imports.
- No `!` null assertion operator anywhere in the new files.
- No `dynamic` — use `Object` or `Object?`.
- No private `_buildXxx` methods — extract as separate widget classes.
- Page width: 120 characters; trailing commas in all multi-line constructs.
- Blank line before every `return` that follows preceding code.
- `const` constructors and `const` widget instances wherever possible.
- Minimum touch target 48×48 dp for all interactive widgets.
- All interactive widgets must carry a `Semantics` label.

---

## Out Of Scope

- Actual QR code rendering (deferred to a future phase or ticket).
- Transaction history, balance, or any non-address RPC calls.
- Settings screen, theming, or `ui_kit` token integration.
- Navigation route constants and `AppRouter` (Phase 7).
- Wiring `WalletScope` and `AppDependenciesBuilder` into `App` (Phase 7).
- Any new BLoC events or state fields beyond what Phase 5 delivered.
- Persistence of UI state across app restarts (that is handled by BLoC/repo).

---

## Open Questions

- [ ] None
