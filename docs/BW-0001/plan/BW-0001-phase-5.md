# Plan: BW-0001 Phase 5 — BLoC

Status: `PLAN_APPROVED` _(post-QA architectural refactoring applied — see note below)_

> **Architectural refactoring note:** After QA, the BLoC layer was restructured:
> - BLoC files moved to `bloc/wallet/` and `bloc/address/` sub-namespaces
> - `WalletBloc` and `AddressBloc` constructors changed to receive use cases
>   (from `lib/feature/wallet/domain/usecase/`) instead of repositories
> - `WalletScope` changed from a pure `InheritedWidget` to a `StatefulWidget`
>   + internal `_InheritedWalletScope` pattern for proper lifecycle management
> - Use cases are created inside `WalletScopeBlocFactory` constructor
Ticket: BW-0001
Phase: 5
Lane: Professional
Workflow Version: 3
Owner: Planner / Architect

---

## Phase Scope

Deliver `WalletBloc`, `AddressBloc`, and `WalletScope` — the complete
presentation-logic layer for the wallet feature. No new domain or data code.
Phase 6 (screens) can start immediately after.

---

## File Changes

| File | Change | Why |
|------|--------|-----|
| `lib/feature/wallet/bloc/wallet_event.dart` | Create | Sealed event hierarchy for WalletBloc |
| `lib/feature/wallet/bloc/wallet_state.dart` | Create | Immutable state + WalletStatus enum |
| `lib/feature/wallet/bloc/wallet_bloc.dart` | Create | WalletBloc implementation |
| `lib/feature/wallet/bloc/address_event.dart` | Create | Sealed event hierarchy for AddressBloc |
| `lib/feature/wallet/bloc/address_state.dart` | Create | Immutable state + AddressStatus enum |
| `lib/feature/wallet/bloc/address_bloc.dart` | Create | AddressBloc implementation |
| `lib/feature/wallet/di/wallet_scope.dart` | Create | WalletScope InheritedWidget + WalletScopeBlocFactory |

All files are new. No existing files are modified in this phase.

---

## Interfaces And Contracts

### WalletStatus

```dart
enum WalletStatus {
  initial,
  loading,
  loaded,
  creating,
  awaitingSeedConfirmation,
  error,
}
```

### WalletState

```dart
final class WalletState {
  const WalletState({
    this.wallets = const [],
    this.status = WalletStatus.initial,
    this.pendingWallet,
    this.pendingMnemonic,
    this.errorMessage,
  });

  final List<Wallet> wallets;
  final WalletStatus status;
  final Wallet? pendingWallet;
  final Mnemonic? pendingMnemonic;
  final String? errorMessage;

  WalletState copyWith({
    List<Wallet>? wallets,
    WalletStatus? status,
    Wallet? pendingWallet,
    Object? pendingWalletOrNull = _sentinel,  // see note below
    Mnemonic? pendingMnemonic,
    Object? pendingMnemonicOrNull = _sentinel,
    String? errorMessage,
    Object? errorMessageOrNull = _sentinel,
  });
}
```

> Note: nullable fields that must be explicitly clearable use the sentinel
> pattern. Alternatively, use overloaded copyWith with explicit `clearPending`
> bool flags — either approach is acceptable. The implementer must choose one
> and apply it consistently. The sentinel pattern is preferred for clarity.
>
> Simplest acceptable alternative: explicit `copyWith` parameters
> `clearPendingWallet`, `clearPendingMnemonic`, `clearErrorMessage` of type
> `bool` defaulting to `false`.

### WalletEvent (sealed)

```dart
sealed class WalletEvent {
  const WalletEvent();
}

final class WalletListRequested extends WalletEvent {
  const WalletListRequested();
}

final class NodeWalletCreateRequested extends WalletEvent {
  const NodeWalletCreateRequested({required this.name});
  final String name;
}

final class HdWalletCreateRequested extends WalletEvent {
  const HdWalletCreateRequested({required this.name, this.wordCount = 12});
  final String name;
  final int wordCount;
}

final class WalletRestoreRequested extends WalletEvent {
  const WalletRestoreRequested({required this.name, required this.mnemonic});
  final String name;
  final Mnemonic mnemonic;
}

final class SeedConfirmed extends WalletEvent {
  const SeedConfirmed({required this.walletId});
  final String walletId;
}

final class SeedViewRequested extends WalletEvent {
  const SeedViewRequested({required this.walletId});
  final String walletId;
}
```

### WalletBloc

```dart
final class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc({
    required NodeWalletRepository nodeWalletRepository,
    required HdWalletRepository hdWalletRepository,
    required SeedRepository seedRepository,
  });

  final NodeWalletRepository _nodeWalletRepository;
  final HdWalletRepository _hdWalletRepository;
  final SeedRepository _seedRepository;

  // Registered handlers (all private):
  Future<void> _onWalletListRequested(WalletListRequested event, Emitter<WalletState> emit);
  Future<void> _onNodeWalletCreateRequested(NodeWalletCreateRequested event, Emitter<WalletState> emit);
  Future<void> _onHdWalletCreateRequested(HdWalletCreateRequested event, Emitter<WalletState> emit);
  Future<void> _onWalletRestoreRequested(WalletRestoreRequested event, Emitter<WalletState> emit);
  Future<void> _onSeedConfirmed(SeedConfirmed event, Emitter<WalletState> emit);
  Future<void> _onSeedViewRequested(SeedViewRequested event, Emitter<WalletState> emit);
}
```

### AddressStatus

```dart
enum AddressStatus {
  initial,
  loading,
  loaded,
  generating,
  error,
}
```

### AddressState

```dart
final class AddressState {
  const AddressState({
    this.addresses = const [],
    this.status = AddressStatus.initial,
    this.lastGenerated,
    this.errorMessage,
  });

  final List<Address> addresses;
  final AddressStatus status;
  final Address? lastGenerated;
  final String? errorMessage;

  AddressState copyWith({
    List<Address>? addresses,
    AddressStatus? status,
    Address? lastGenerated,
    String? errorMessage,
  });
}
```

### AddressEvent (sealed)

```dart
sealed class AddressEvent {
  const AddressEvent();
}

final class AddressListRequested extends AddressEvent {
  const AddressListRequested({required this.wallet});
  final Wallet wallet;
}

final class AddressGenerateRequested extends AddressEvent {
  const AddressGenerateRequested({required this.wallet, required this.type});
  final Wallet wallet;
  final AddressType type;
}
```

### AddressBloc

```dart
final class AddressBloc extends Bloc<AddressEvent, AddressState> {
  AddressBloc({required WalletRepository walletRepository});

  final WalletRepository _walletRepository;

  Future<void> _onAddressListRequested(AddressListRequested event, Emitter<AddressState> emit);
  Future<void> _onAddressGenerateRequested(AddressGenerateRequested event, Emitter<AddressState> emit);
}
```

> Note: `AddressBloc` receives `WalletRepository` (the base interface) because
> both `NodeWalletRepository` and `HdWalletRepository` extend it. The factory
> selects the correct implementation based on `wallet.type` before instantiating
> `AddressBloc`, or `WalletScope` can supply typed variants. The simpler
> approach: `WalletScopeBlocFactory.addressBloc(Wallet)` receives the wallet
> and resolves the correct repository internally.

### WalletScope and WalletScopeBlocFactory

```dart
/// Factory that creates BLoC instances with injected dependencies.
final class WalletScopeBlocFactory {
  const WalletScopeBlocFactory({
    required NodeWalletRepository nodeWalletRepository,
    required HdWalletRepository hdWalletRepository,
    required SeedRepository seedRepository,
  });

  final NodeWalletRepository _nodeWalletRepository;
  final HdWalletRepository _hdWalletRepository;
  final SeedRepository _seedRepository;

  /// Creates a new [WalletBloc] wired to all three repositories.
  WalletBloc walletBloc() => WalletBloc(
    nodeWalletRepository: _nodeWalletRepository,
    hdWalletRepository: _hdWalletRepository,
    seedRepository: _seedRepository,
  );

  /// Creates a new [AddressBloc] for the given [wallet].
  ///
  /// Selects [NodeWalletRepository] or [HdWalletRepository] based on
  /// [wallet.type].
  AddressBloc addressBloc(Wallet wallet) => AddressBloc(
    walletRepository: wallet.type == WalletType.node
        ? _nodeWalletRepository
        : _hdWalletRepository,
  );
}

/// Feature-scoped InheritedWidget that exposes [WalletScopeBlocFactory].
class WalletScope extends InheritedWidget {
  const WalletScope({
    super.key,
    required this.blocFactory,
    required super.child,
  });

  final WalletScopeBlocFactory blocFactory;

  static WalletScopeBlocFactory of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WalletScope>();
    if (scope == null) {
      throw StateError('WalletScope not found in widget tree');
    }

    return scope.blocFactory;
  }

  @override
  bool updateShouldNotify(WalletScope oldWidget) => blocFactory != oldWidget.blocFactory;
}
```

---

## Sequencing

1. **Create state files first** — `wallet_state.dart` (+ `WalletStatus`) and
   `address_state.dart` (+ `AddressStatus`). No dependencies on other new files.

2. **Create event files** — `wallet_event.dart` and `address_event.dart`.
   These depend only on domain entities (`Wallet`, `Mnemonic`, `AddressType`).

3. **Implement `WalletBloc`** — `wallet_bloc.dart`. Depends on state and event
   files just created, plus domain interfaces.

4. **Implement `AddressBloc`** — `address_bloc.dart`. Same pattern; shorter.

5. **Implement `WalletScope`** — `wallet_scope.dart`. Depends on both BLoC
   classes and domain interfaces. No UI code yet.

6. **Run `flutter analyze`** and fix any issues before declaring batch complete.

---

## Error Handling And Edge Cases

- **`isClosed` guard** — every handler that performs at least one `await` must
  check `if (isClosed) return;` immediately before each subsequent `emit()`.
  Use `Emitter.isDone` when using `emit.forEach` or `emit.onEach`; otherwise
  check `isClosed` directly.

- **Repository exception** — wrap every repository call in `try/catch`. On
  catch, emit `status: WalletStatus.error` (or `AddressStatus.error`) with
  `errorMessage: e.toString()`. Do not re-throw.

- **`SeedViewRequested` when seed missing** — if `SeedRepository.getSeed`
  returns `null`, emit `status: error, errorMessage: 'Seed not found for wallet $walletId'`.
  Never emit a null `pendingMnemonic` as though it were valid data.

- **`AddressGenerateRequested` guard** — if `state.status == AddressStatus.generating`,
  return early without emitting. This prevents double-tap racing.

- **`pendingMnemonic` cleared on confirm** — `SeedConfirmed` handler must emit
  state with `pendingWallet: null` and `pendingMnemonic: null`. Never keep the
  mnemonic in BLoC state after confirmation.

- **`WalletListRequested` merges two repositories** — call
  `nodeWalletRepository.getWallets()` and `hdWalletRepository.getWallets()`
  sequentially (or with `Future.wait`). Concatenate results. If one fails, emit
  `error`; do not emit a partial list silently.

---

## Checks

- `flutter analyze --fatal-infos --fatal-warnings` must pass with zero issues.
- Manually verify: add a breakpoint or `log()` in `_onHdWalletCreateRequested`
  and confirm `state.status` transitions to `awaitingSeedConfirmation` and
  `state.pendingMnemonic` is non-null.
- Manually verify: `SeedConfirmed` clears `pendingMnemonic` to null.
- Manually verify: `AddressGenerateRequested` on an HD wallet populates
  `lastGenerated.derivationPath`.

---

## Risks

- `copyWith` with nullable sentinel: if the implementer chooses the sentinel
  pattern, they must ensure `_sentinel` is a private `const Object()` and is
  not accidentally exported. The bool-flag alternative is simpler and safe.
- `WalletBloc` holds `pendingMnemonic` (a `Mnemonic` value object) in state.
  `Mnemonic` has no `toString()` — this is intentional and must not be changed.
  Logging tools that reflect state must not be configured to call `toString()`
  on state fields.
- `Future.wait` for `getWallets` from both repos: if both repos share the same
  underlying `WalletLocalStore` key prefix, results will not duplicate. Verify
  key prefixes (`node_` vs `hd_`) are distinct — they are, per Phase 3/4
  implementation.
