# Phase 6: UI Screens

Status: `IMPLEMENTATION_DONE`
Ticket: BW-0001
Phase: 6
Lane: Professional
Workflow Version: 3
Owner: Implementer

---

## Goal

Implement all six wallet feature screens and three supporting widgets as pure view widgets bound to the BLoC layer from Phase 5.

## Context

Screens receive BLoC instances via constructor; no DI inside screen files. Navigation callbacks are typed stubs — Phase 7 wires real routes.

## Tasks

- [x] 6.0 Create `lib/common/utils/bip39_wordlist.dart` — 2048-word BIP39 constant
- [x] 6.1 `view/screen/list/wallet_list_screen.dart` — list + FAB + empty state + SnackBar on error
- [x] 6.2 `view/screen/setup/create_wallet_screen.dart` — RadioGroup type selector + name input + BlocConsumer
- [x] 6.3 `view/screen/setup/seed_phrase_screen.dart` — mnemonic grid + warning banner + checkbox + SeedConfirmed
- [x] 6.4 `view/screen/setup/restore_wallet_screen.dart` — seed input + real-time BIP39 validation + word highlight
- [x] 6.5 `view/screen/detail/wallet_detail_screen.dart` — AddressTypeSection per type + View Seed for HD
- [x] 6.6 `view/screen/detail/address_screen.dart` — address + copy + [QR] placeholder + derivation path
- [x] Widgets: `view/widget/wallet_card.dart`, `view/widget/seed_word_tile.dart`, `view/widget/address_type_section.dart`
- [x] `flutter analyze --fatal-infos --fatal-warnings` — zero issues
- [x] `dcm analyze` — zero issues

## Acceptance Criteria

- All nine new files exist under `lib/feature/wallet/view/` and `lib/common/utils/`
- No `AppScope.of` / `WalletScope.of` inside any screen file
- No relative imports, no `!` null assertion, no `dynamic`
- `flutter analyze --fatal-infos --fatal-warnings` exits 0
- `dcm analyze` exits 0

## Dependencies

- Phase 5 (BLoC layer)

## Technical Details

- `RadioGroup<WalletType>` with `groupValue` + `AbsorbPointer` for disabled state (Flutter 3.41 API)
- DCM member ordering for State classes: `initState → private methods → dispose → build`
- BIP39 wordlist: 2048 words from official trezor/python-mnemonic source
- `_WordHighlight` extracted as private `StatelessWidget` in restore_wallet_screen.dart
