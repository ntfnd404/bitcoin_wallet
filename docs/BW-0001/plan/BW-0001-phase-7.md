# Plan: BW-0001 Phase 7 — Navigation & Integration

Status: `PLAN_APPROVED`
Ticket: BW-0001
Phase: 7
Lane: Professional
Workflow Version: 3
Owner: Planner

---

## Phase Scope

Three file operations (one create, two modify) that wire screens, routing, and DI into a
fully runnable app.

---

## File Changes

| File | Change | Why |
|------|--------|-----|
| `lib/core/routing/app_router.dart` | Create | Centralised navigation logic |
| `lib/app.dart` | Modify | App → StatefulWidget; WalletScope; real home |
| `lib/core/di/app_dependencies_builder.dart` | Modify | Replace stubs with real impls |

---

## Interfaces And Contracts

### AppRouter

```dart
/// Centralised navigation helpers.
final class AppRouter {
  const AppRouter._();

  // Route name constants (informational only).
  static const String walletList    = '/';
  static const String createWallet  = '/wallet/create';
  static const String seedPhrase    = '/wallet/seed';
  static const String restoreWallet = '/wallet/restore';
  static const String walletDetail  = '/wallet/detail';
  static const String address       = '/wallet/address';

  static Future<void> toCreateWallet(BuildContext context, WalletScopeBlocFactory factory);
  static Future<void> toRestoreWallet(BuildContext context, WalletScopeBlocFactory factory);
  static Future<void> toWalletDetail(
    BuildContext context, WalletScopeBlocFactory factory, WalletBloc listBloc, Wallet wallet,
  );
  static Future<void> toAddress(BuildContext context, Address address);
  static Future<void> toSeedPhrase(
    BuildContext context, WalletBloc bloc, Mnemonic mnemonic, String walletId,
  );
}
```

#### toCreateWallet

1. Creates a fresh `WalletBloc` via `factory.walletBloc()`.
2. Pushes `CreateWalletScreen` with:
   - `onNodeWalletCreated(wallet)` → calls `_onNodeCreated(context, factory, createBloc, wallet)`.
   - `onHdWalletPendingSeed()` → reads `createBloc.state`; guards nulls; calls
     `_onHdPendingSeed(context, createBloc)`.
3. Returns the push Future (resolves when the route stack returns to WalletListScreen).

#### _onNodeCreated (private static)

- `Navigator.pushReplacement` with `WalletDetailScreen` (replaces CreateWalletScreen).
- `WalletDetailScreen` callbacks: `onAddressSelected` → `toAddress`; `onViewSeed` → `toSeedPhrase`.

#### _onHdPendingSeed (private static)

- Reads `mnemonic` and `pendingWallet` from `bloc.state`; returns early if either is null.
- `Navigator.push` `SeedPhraseScreen`.
- `SeedPhraseScreen.onConfirmed` → `Navigator.popUntil(context, (route) => route.isFirst)`.

#### toRestoreWallet

- Creates a fresh `WalletBloc` from factory.
- Pushes `RestoreWalletScreen`.
- `onRestored(wallet)` → `Navigator.pushReplacement` with `WalletDetailScreen`.

#### toWalletDetail

- Creates `addressBloc` via `factory.addressBloc(wallet)`.
- Pushes `WalletDetailScreen`.
- `walletBloc` = `listBloc` (shared) so View Seed updates list state.
- `onViewSeed` → reads `listBloc.state.pendingMnemonic`; guards null; calls `toSeedPhrase`.

#### toAddress / toSeedPhrase

Simple `Navigator.push` of the respective screen.

---

### App (modified)

```dart
class App extends StatefulWidget { ... }

class _AppState extends State<App> {
  late final WalletScopeBlocFactory _factory;
  late final WalletBloc _walletBloc;

  @override
  void initState() { /* create factory and walletBloc */ }

  @override
  void dispose() { /* _walletBloc.close() */ }

  @override
  Widget build(BuildContext context) => WalletScope(
    blocFactory: _factory,
    child: MaterialApp(
      home: WalletListScreen(
        bloc: _walletBloc,
        onCreateWallet: () async {
          await AppRouter.toCreateWallet(context, _factory);
          if (mounted) _walletBloc.add(const WalletListRequested());
        },
        onWalletSelected: (wallet) =>
            AppRouter.toWalletDetail(context, _factory, _walletBloc, wallet),
      ),
    ),
  );
}
```

Key points:
- `_walletBloc` is owned by `_AppState` and disposed in `dispose()`.
- `WalletListScreen` wraps it with `BlocProvider(create: (_) => widget.bloc)` — this is the
  long-lived provider since the home is never popped.
- After `toCreateWallet` resolves (all pushed routes popped), `WalletListRequested` is fired
  to refresh the list from both repos.
- `mounted` guard before adding event is required because `await` crosses a frame.

---

### AppDependenciesBuilder (modified)

Replace `_StubHdWalletRepository` and `_StubSeedRepository` with:

```dart
final seedRepository = SeedRepositoryImpl(storage: storage);
final bip39Service = const Bip39ServiceImpl();
final keyDerivationService = const KeyDerivationServiceImpl();

return AppDependencies(
  nodeWalletRepository: NodeWalletRepositoryImpl(...),
  hdWalletRepository: HdWalletRepositoryImpl(
    bip39Service: bip39Service,
    keyDerivationService: keyDerivationService,
    seedRepository: seedRepository,
    storage: storage,
  ),
  seedRepository: seedRepository,
  bip39Service: bip39Service,
  keyDerivationService: keyDerivationService,
);
```

Remove the two stub classes entirely.

---

## Sequencing

1. Modify `app_dependencies_builder.dart` — eliminates stubs; no UI dependency.
2. Create `app_router.dart` — depends on all Phase 6 screens being importable.
3. Modify `app.dart` — depends on `AppRouter` and `WalletScope`.
4. Run `flutter analyze --fatal-infos --fatal-warnings` — must exit 0.

---

## Error Handling And Edge Cases

- `pendingMnemonic == null` in `_onHdPendingSeed`: guard with early return; this would only
  happen if the callback fires before the BLoC processes the event (impossible in practice).
- `mounted` check after `await AppRouter.toCreateWallet`: prevents adding events to a
  disposed bloc if `_AppState` was somehow disposed mid-navigation.
- `_walletBloc.close()` in `_AppState.dispose()` vs BlocProvider in `WalletListScreen`:
  BlocProvider's close runs first (widget tree teardown), then `_AppState.dispose()` runs.
  Calling `close()` on an already-closed bloc is a no-op in flutter_bloc — safe.

---

## Checks

- `flutter analyze --fatal-infos --fatal-warnings` — zero issues.
- Manual: launch → WalletListScreen (empty state).
- Manual: create Node wallet → WalletDetailScreen → generate all 4 address types → AddressScreen.
- Manual: create HD wallet → SeedPhraseScreen → confirm → WalletListScreen shows HD wallet.
- Manual: tap HD wallet → WalletDetailScreen → View Seed → SeedPhraseScreen (words visible).
- Manual: tap Node wallet → WalletDetailScreen → no View Seed button.
- Manual: AddressScreen → Copy → paste confirms full address string.
- Code review: no stubs in AppDependenciesBuilder.
- Code review: no `!` in any new or modified file.
