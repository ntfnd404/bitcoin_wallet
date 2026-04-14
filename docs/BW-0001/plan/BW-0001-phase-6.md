# Plan: BW-0001 Phase 6 — UI Screens

Status: `PLAN_APPROVED`
Ticket: BW-0001
Phase: 6
Lane: Professional
Workflow Version: 3
Owner: Planner / Architect

---

## Phase Scope

Create all six wallet-feature screens and three extracted supporting widgets.
Every screen is a pure view widget: it owns no repositories, calls no DI, and
performs no BLoC construction. BLoC instances arrive via `BlocProvider(create:
...)` passed to the screen as a constructor argument or — for screens that open
inside a subtree that already has a provider — consumed via `BlocBuilder` /
`BlocListener`. Navigation is stub-ready: each screen declares typed callbacks
(`VoidCallback`, `void Function(Wallet)`, etc.) so Phase 7 can wire real routes
without touching screen code.

---

## File Changes

| File | Change | Why |
|------|--------|-----|
| `lib/feature/wallet/view/screen/list/wallet_list_screen.dart` | Create | Task 6.1 — wallet list + FAB + empty state |
| `lib/feature/wallet/view/screen/setup/create_wallet_screen.dart` | Create | Task 6.2 — type selector + name input |
| `lib/feature/wallet/view/screen/setup/seed_phrase_screen.dart` | Create | Task 6.3 — mnemonic grid + confirmation |
| `lib/feature/wallet/view/screen/setup/restore_wallet_screen.dart` | Create | Task 6.4 — seed input + BIP39 validation |
| `lib/feature/wallet/view/screen/detail/wallet_detail_screen.dart` | Create | Task 6.5 — address list + generate + view seed |
| `lib/feature/wallet/view/screen/detail/address_screen.dart` | Create | Task 6.6 — address display + copy + QR placeholder |
| `lib/feature/wallet/view/widget/wallet_card.dart` | Create | Reusable wallet list tile extracted from WalletListScreen |
| `lib/feature/wallet/view/widget/seed_word_tile.dart` | Create | Indexed word cell used in the mnemonic grid |
| `lib/feature/wallet/view/widget/address_type_section.dart` | Create | Address group header + list for one AddressType |

No existing files are modified in this phase.

---

## Interfaces And Contracts

### WalletListScreen

```dart
/// Displays a list of wallets loaded by [WalletBloc].
///
/// Receives the bloc and navigation callbacks from the caller; owns no DI.
class WalletListScreen extends StatelessWidget {
  const WalletListScreen({
    super.key,
    required this.bloc,
    required this.onCreateWallet,
    required this.onWalletSelected,
  });

  /// Pre-created [WalletBloc] instance. Provided to the tree via
  /// [BlocProvider(create: (_) => bloc)].
  final WalletBloc bloc;

  /// Called when the user taps the FAB to open [CreateWalletScreen].
  final VoidCallback onCreateWallet;

  /// Called when the user selects a wallet from the list.
  final void Function(Wallet wallet) onWalletSelected;

  @override
  Widget build(BuildContext context) { ... }
}
```

`build` wraps children in `BlocProvider(create: (_) => bloc, child: ...)`.
`BlocBuilder<WalletBloc, WalletState>` reacts to state changes.
`BlocListener<WalletBloc, WalletState>` shows a `SnackBar` on `status == error`.
On `initState`-equivalent: fire `WalletListRequested` inside `BlocProvider`'s
`create` callback after construction — or use a `StatefulWidget` `initState` to
call `bloc.add(const WalletListRequested())`.

Design note: because `WalletListScreen` must fire `WalletListRequested` on
mount, it should be a `StatefulWidget` with `initState` calling
`bloc.add(const WalletListRequested())`.

### WalletCard

```dart
/// A single wallet list tile.
class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.wallet,
    required this.onTap,
  });

  final Wallet wallet;
  final VoidCallback onTap;
}
```

Displays `wallet.name`, wallet type chip (`Node` / `HD`), and formatted
`wallet.createdAt`. Uses `ListTile`.

### CreateWalletScreen

```dart
/// Allows the user to choose a wallet type and enter a wallet name.
class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({
    super.key,
    required this.bloc,
    required this.onNodeWalletCreated,
    required this.onHdWalletPendingSeed,
  });

  /// Pre-created [WalletBloc] shared with [WalletListScreen].
  final WalletBloc bloc;

  /// Called when [WalletBloc] transitions to [WalletStatus.loaded] after a
  /// Node wallet creation — carries the newly created wallet.
  final void Function(Wallet wallet) onNodeWalletCreated;

  /// Called when [WalletBloc] transitions to
  /// [WalletStatus.awaitingSeedConfirmation] — the mnemonic is in
  /// [WalletState.pendingMnemonic].
  final VoidCallback onHdWalletPendingSeed;
}
```

Internal `_CreateWalletScreenState` fields:
- `WalletType _selectedType` (default `WalletType.node`)
- `TextEditingController _nameController`
- `bool _isSubmitting` derived from `state.status`

`BlocListener` drives navigation callbacks:
- `status == loaded` and previous status was `creating` → call `onNodeWalletCreated(state.wallets.last)`.
- `status == awaitingSeedConfirmation` → call `onHdWalletPendingSeed()`.
- `status == error` → show `SnackBar` with `state.errorMessage`.

Submit fires either `NodeWalletCreateRequested` or
`HdWalletCreateRequested(wordCount: 12)` based on `_selectedType`.
Button is disabled when `_nameController.text.trim().isEmpty` or status is `creating`.

### SeedPhraseScreen

```dart
/// Shows the generated mnemonic and requires the user to confirm they saved it.
class SeedPhraseScreen extends StatefulWidget {
  const SeedPhraseScreen({
    super.key,
    required this.bloc,
    required this.mnemonic,
    required this.walletId,
    required this.onConfirmed,
  });

  /// The BLoC used only to dispatch [SeedConfirmed].
  final WalletBloc bloc;

  /// Mnemonic to display. Obtained from [WalletState.pendingMnemonic] by the
  /// caller before navigation; passed explicitly so the screen does not read
  /// sensitive data from BLoC state at build time.
  final Mnemonic mnemonic;

  /// The pending wallet id used in [SeedConfirmed].
  final String walletId;

  /// Called after [SeedConfirmed] is dispatched and BLoC emits [loaded].
  final VoidCallback onConfirmed;
}
```

Internal `_SeedPhraseScreenState` fields:
- `bool _confirmed` (checkbox state, default `false`)

Layout:
1. Warning banner — `Container` with amber background and a lock icon: "Write
   down your seed phrase. Anyone who sees it can access your funds."
2. `GridView` (2 columns) of `SeedWordTile` widgets. Mnemonic words are read
   from `mnemonic.words` (list of `String`). The screen does not call
   `mnemonic.toString()`.
3. Checkbox: "I have saved my seed phrase" — toggles `_confirmed`.
4. Continue `ElevatedButton` — disabled when `!_confirmed`; on press dispatches
   `SeedConfirmed(walletId: walletId)` and calls `onConfirmed()`.

`BlocListener` listens for `status == error` → show `SnackBar`.

### SeedWordTile

```dart
/// Displays an indexed BIP39 word inside the mnemonic grid.
class SeedWordTile extends StatelessWidget {
  const SeedWordTile({super.key, required this.index, required this.word});

  /// 1-based word index.
  final int index;
  final String word;
}
```

Renders `"$index. $word"` in a bordered `Container`. Font: monospace via
`TextStyle(fontFamily: 'monospace')`.

### RestoreWalletScreen

```dart
/// Allows the user to restore an HD wallet by entering an existing seed phrase.
class RestoreWalletScreen extends StatefulWidget {
  const RestoreWalletScreen({
    super.key,
    required this.bloc,
    required this.onRestored,
  });

  final WalletBloc bloc;

  /// Called after BLoC emits [WalletStatus.loaded] following a successful
  /// restore.
  final void Function(Wallet wallet) onRestored;
}
```

Internal `_RestoreWalletScreenState` fields:
- `TextEditingController _nameController`
- `TextEditingController _phraseController`
- `List<String> _invalidWords` — updated on every phrase change

Validation logic (pure, no BLoC):
- Split `_phraseController.text` by whitespace → `words`.
- Accept only 12 or 24 words.
- For each word, check membership in the BIP39 English wordlist embedded as a
  compile-time `const List<String>` in the widget file (or a separate
  `lib/common/utils/bip39_wordlist.dart` constant). Words not in the list are
  added to `_invalidWords`.
- Restore button enabled only when `words.length == 12 || words.length == 24`
  and `_invalidWords.isEmpty` and `_nameController.text.trim().isNotEmpty`.

On submit: `bloc.add(WalletRestoreRequested(name: name, mnemonic: Mnemonic(words: words)))`.

`BlocListener`:
- `status == loaded` (after `creating`) → call `onRestored(state.wallets.last)`.
- `status == error` → show `SnackBar`.

Invalid words are highlighted in the text field by rendering the full phrase in
a `Text.rich` widget below the text field — words in `_invalidWords` shown in
red, others in the default colour. This avoids custom `TextEditingController`
painting complexity while still providing real-time feedback.

Design note: The BIP39 wordlist (2048 words) is a constant that must be placed
in `lib/common/utils/bip39_wordlist.dart` as:
```dart
const List<String> kBip39EnglishWordlist = [ ... ];
```
This file is new. It depends only on `dart:core`. `RestoreWalletScreen` imports
it via `package:bitcoin_wallet/common/utils/bip39_wordlist.dart`.

### WalletDetailScreen

```dart
/// Shows addresses for a single wallet grouped by [AddressType].
///
/// Owns an [AddressBloc] created from [WalletScopeBlocFactory] passed in.
class WalletDetailScreen extends StatefulWidget {
  const WalletDetailScreen({
    super.key,
    required this.wallet,
    required this.addressBloc,
    required this.walletBloc,
    required this.onAddressSelected,
    required this.onViewSeed,
  });

  final Wallet wallet;

  /// Pre-created [AddressBloc] for this wallet. Provided via
  /// [BlocProvider(create: (_) => addressBloc)].
  final AddressBloc addressBloc;

  /// Needed only to dispatch [SeedViewRequested] for HD wallets.
  final WalletBloc walletBloc;

  /// Called when the user taps an address row.
  final void Function(Address address) onAddressSelected;

  /// Called when the user taps "View Seed" (HD wallets only).
  final VoidCallback onViewSeed;
}
```

`initState` fires `AddressListRequested(wallet: wallet)`.

Layout:
- `AppBar` with `wallet.name`.
- If `wallet.type == WalletType.hd`: an "View Seed" `TextButton` in the app
  bar actions; on press fires `SeedViewRequested(walletId: wallet.id)` on
  `walletBloc` and calls `onViewSeed()`.
- Body: `ListView` of `AddressTypeSection` widgets — one per `AddressType` value.
- Each `AddressTypeSection` receives the filtered address list and a "Generate"
  button callback that fires
  `AddressGenerateRequested(wallet: wallet, type: type)` on `addressBloc`.
- While `status == generating`, the Generate button shows a
  `CircularProgressIndicator` of size 16 instead of its label.

`BlocListener<AddressBloc, AddressState>` shows a `SnackBar` on error.

### AddressTypeSection

```dart
/// Renders the header and address list for a single [AddressType].
class AddressTypeSection extends StatelessWidget {
  const AddressTypeSection({
    super.key,
    required this.type,
    required this.addresses,
    required this.isGenerating,
    required this.onGenerate,
    required this.onAddressSelected,
  });

  final AddressType type;
  final List<Address> addresses;

  /// True when [AddressBloc] status is [AddressStatus.generating].
  final bool isGenerating;

  final VoidCallback onGenerate;
  final void Function(Address address) onAddressSelected;
}
```

Renders:
- `Text` section header: type label (see label mapping below).
- `ListTile` per address: abbreviated address value (`value.substring(0, 12) + '...'`).
- An "Generate" `OutlinedButton` at the bottom of the section; disabled and shows
  a 16 px `CircularProgressIndicator` when `isGenerating`.

Address type → display label mapping (constant in the widget file):
```dart
const _typeLabels = {
  AddressType.legacy: 'Legacy (P2PKH)',
  AddressType.wrappedSegwit: 'Wrapped SegWit (P2SH-P2WPKH)',
  AddressType.nativeSegwit: 'Native SegWit (P2WPKH)',
  AddressType.taproot: 'Taproot (P2TR)',
};
```

### AddressScreen

```dart
/// Displays a single address with copy action, QR placeholder, and path info.
class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key, required this.address});

  final Address address;
}
```

Layout (Column, centered):
1. `SelectableText(address.value, ...)` — full address, selectable and
   word-wrapping.
2. `ElevatedButton.icon(icon: Icon(Icons.copy), label: Text('Copy'))` — on
   press calls `Clipboard.setData(ClipboardData(text: address.value))` and
   shows a `SnackBar('Address copied')` via `ScaffoldMessenger.of(context)`.
3. `Text('[QR]', style: TextStyle(fontSize: 48))` — QR placeholder.
4. `Text(address.derivationPath ?? 'Managed by Bitcoin Core')` — derivation
   path row.

No BLoC involvement. `AddressScreen` is a pure display widget.

---

## Sequencing

The tasks within this phase form two independent groups that share no
intermediate output, so they can be built sequentially in one batch:

1. **Create `lib/common/utils/bip39_wordlist.dart`** — the 2048-word
   constant list. Required by `RestoreWalletScreen`. No other dependencies.

2. **Create `wallet_card.dart`** — no BLoC dependency; depends only on
   `domain/Wallet` entity. Allows `WalletListScreen` to be written cleanly.

3. **Create `seed_word_tile.dart`** — no dependency on any widget or BLoC.
   Required by `SeedPhraseScreen`.

4. **Create `address_type_section.dart`** — depends on `AddressType` and
   `Address` domain entities. Required by `WalletDetailScreen`.

5. **Create `wallet_list_screen.dart`** — depends on `WalletCard`,
   `WalletBloc`, `WalletState`. This is task 6.1.

6. **Create `create_wallet_screen.dart`** — depends on `WalletBloc`,
   `WalletState`, `WalletType`. Task 6.2.

7. **Create `seed_phrase_screen.dart`** — depends on `SeedWordTile`,
   `WalletBloc`, `Mnemonic`. Task 6.3.

8. **Create `restore_wallet_screen.dart`** — depends on `bip39_wordlist.dart`,
   `WalletBloc`, `Mnemonic`. Task 6.4.

9. **Create `wallet_detail_screen.dart`** — depends on `AddressTypeSection`,
   `AddressBloc`, `AddressState`, `WalletBloc`. Task 6.5.

10. **Create `address_screen.dart`** — depends on `Address` entity only.
    Task 6.6. No BLoC.

11. **Run `flutter analyze --fatal-infos --fatal-warnings`** — must pass
    with zero issues before declaring the phase complete.

---

## Error Handling And Edge Cases

- **`state.pendingMnemonic` is null when `SeedPhraseScreen` mounts** — this
  should never happen if navigation is wired correctly, but the screen receives
  `mnemonic` as a required constructor parameter (not read from state at build
  time). If the caller passes `state.pendingMnemonic` and it is null, the
  compile-time type system prevents passing it without a null check — the caller
  must guard before navigating.

- **`SeedConfirmed` dispatched while BLoC is closed** — `WalletBloc` already
  guards with `isClosed`. The screen's `onConfirmed` callback is called
  immediately after dispatching; if the BLoC closes between dispatch and
  callback, the screen's navigation will still execute (harmless).

- **`RestoreWalletScreen` wordlist constant size** — 2048 words × ~8 bytes
  average = ~16 KB. Acceptable as a compile-time constant.

- **BIP39 word highlighting** — word validation runs synchronously inside
  `setState` on every text change. No debounce is required at this word count.

- **`WalletDetailScreen.onViewSeed`** — fires `SeedViewRequested` on
  `walletBloc` and then calls `onViewSeed()` immediately. The caller is
  responsible for reading `state.pendingMnemonic` to pass to
  `SeedPhraseScreen`. There is no race condition because the BLoC processes
  events sequentially.

- **Address list empty state in `WalletDetailScreen`** — each
  `AddressTypeSection` renders nothing (or a hint text) when its address list
  is empty. The Generate button is always shown.

- **`AddressScreen` clipboard on Linux/macOS** — `Clipboard.setData` is
  synchronous on all desktop platforms in Flutter. No additional handling needed.

- **`SelectableText` in `AddressScreen`** — allows manual copy in addition to
  the Copy button. Does not conflict with the button.

- **`WalletListScreen` fires `WalletListRequested` on every mount** — this is
  intentional: each screen mount should refresh the list. The BLoC is not
  recreated on navigation back, so the state is preserved; the re-request will
  simply reload from repositories.

- **Button disabled states** — whenever `status == creating` or
  `status == generating`, all primary action buttons are disabled. Use
  `ElevatedButton(onPressed: _isLoading ? null : _onSubmit, ...)` pattern.
  When `onPressed` is null, Flutter renders the button in its disabled state
  automatically — no custom styling required.

---

## Checks

- `flutter analyze --fatal-infos --fatal-warnings` — zero issues.
- Manual: launch app; `WalletListScreen` shows "No wallets yet" on first run.
- Manual: create a Node wallet; `WalletDetailScreen` opens; Generate for each
  address type; each address starts with expected regtest prefix.
- Manual: create an HD wallet; `SeedPhraseScreen` shows 12 words; checkbox
  required before Continue.
- Manual: restore HD wallet with known phrase; addresses match the original.
- Manual: tap Copy on `AddressScreen`; paste confirms full address.
- Manual: `AddressScreen` for Node wallet shows "Managed by Bitcoin Core".
- Manual: `AddressScreen` for HD wallet shows derivation path.
- Code review: no `AppScope.of` or `WalletScope.of` calls inside any
  `view/screen/` file.
- Code review: no relative imports in any new file.
- Code review: no `!` null assertion in any new file.
- Code review: no `print` — only `dart:developer` `log` if any logging is used.

---

## Risks

- **BIP39 wordlist size** — embedding 2048 words as a `const` list adds ~16 KB
  to the Dart snapshot. Acceptable for a portfolio app; no risk.
- **`BlocProvider` ownership** — because screens receive a pre-created BLoC,
  the caller is responsible for disposing it. Phase 7 must ensure BLoCs are
  created at the correct scope and disposed when the route is popped.
  `BlocProvider(create: (_) => bloc)` disposes the bloc when the widget is
  removed from the tree, which is the correct behaviour when the BLoC is
  created exclusively for that screen.
- **Shared `WalletBloc`** — `WalletListScreen` and `CreateWalletScreen` should
  share the same `WalletBloc` instance (the wallet list must update after
  creation). Phase 7 must place `BlocProvider(create: ...)` at a level that
  spans both screens. In this phase no wiring exists; each screen receives its
  bloc as a constructor parameter, leaving wiring to Phase 7.
- **Word validation wordlist accuracy** — the constant in
  `bip39_wordlist.dart` must be the canonical BIP39 English list. Any typo
  invalidates valid mnemonics. The implementer must copy the list from the
  official BIP39 repository verbatim.
