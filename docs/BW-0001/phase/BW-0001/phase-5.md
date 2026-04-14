# Phase 5: BLoC

Status: `QA_PASS`
Ticket: BW-0001
Phase: 5
Lane: Professional
Workflow Version: 3
Owner: Implementer
Goal: Implement WalletBloc, AddressBloc, and WalletScope so UI screens have a complete state machine to bind to.

Session brief — execution packet only. Do not repeat full architecture rationale here.

> **Architectural note (post-QA refactoring):** BLoC files were reorganized
> into sub-namespaces (`bloc/wallet/`, `bloc/address/`). WalletBloc and
> AddressBloc constructors were updated to receive use cases (from
> `lib/feature/wallet/domain/usecase/`) instead of repositories directly.
> WalletScope was promoted from a pure InheritedWidget to a StatefulWidget
> that owns the factory lifecycle. See Phase 5 summary for details.

---

## Current Batch

Create all seven files for the wallet feature BLoC layer in this order:

1. `lib/feature/wallet/bloc/wallet/wallet_state.dart` + `WalletStatus` enum
2. `lib/feature/wallet/bloc/wallet/wallet_event.dart` (sealed hierarchy)
3. `lib/feature/wallet/bloc/wallet/wallet_bloc.dart`
4. `lib/feature/wallet/bloc/address/address_state.dart` + `AddressStatus` enum
5. `lib/feature/wallet/bloc/address/address_event.dart` (sealed hierarchy)
6. `lib/feature/wallet/bloc/address/address_bloc.dart`
7. `lib/feature/wallet/di/wallet_scope.dart`

---

## Constraints

- BLoC only — never Cubit.
- All event class names are past-tense imperative: `WalletListRequested`, `SeedConfirmed`, etc.
- All state classes are `final class` with a `const` constructor and a hand-written `copyWith`.
- Check `isClosed` before every `emit()` that follows an `await`.
- Never expose public methods or public fields on BLoC — all interaction is through events.
- `BlocProvider(create: ...)` only — never `BlocProvider.value` (relevant to Phase 6 but enforced here by design).
- All imports must be `package:` imports — no relative imports.
- Page width: 120 characters; trailing commas in all multi-line constructs.
- Never use `!` (null assertion); never use `dynamic`.
- Never use `var` when the type is not clear from the right-hand side.
- Blank line before every `return` that follows preceding code.
- No `freezed` or code generation — hand-written immutable classes only.

---

## Execution Checklist

- [x] 5.1 Create `bloc/wallet/wallet_state.dart`
  - `WalletStatus` enum: `initial, loading, loaded, creating, awaitingSeedConfirmation, error`
  - `WalletState` final class: `wallets`, `status`, `pendingWallet?`, `pendingMnemonic?`, `errorMessage?`
  - `copyWith` that can explicitly clear nullable fields (use bool-flag pattern: `clearPendingWallet`, `clearPendingMnemonic`, `clearErrorMessage`, each `bool` defaulting to `false`)

- [x] 5.1 Create `bloc/wallet/wallet_event.dart`
  - `sealed class WalletEvent`
  - `WalletListRequested` (no fields)
  - `NodeWalletCreateRequested({required String name})`
  - `HdWalletCreateRequested({required String name, int wordCount = 12})`
  - `WalletRestoreRequested({required String name, required Mnemonic mnemonic})`
  - `SeedConfirmed({required String walletId})`
  - `SeedViewRequested({required String walletId})`

- [x] 5.1 Create `bloc/wallet/wallet_bloc.dart`
  - Constructor: `({required GetWalletsUseCase, required CreateNodeWalletUseCase, required CreateHdWalletUseCase, required RestoreHdWalletUseCase, required GetSeedUseCase})`
  - `super(const WalletState())` with all `on<>` registrations in constructor body
  - `_onWalletListRequested`: emit `loading`; call `getWallets.execute()`; emit `loaded`; on error emit `error`
  - `_onNodeWalletCreateRequested`: emit `creating`; call `createNodeWallet.execute`; emit `loaded`; on error emit `error`
  - `_onHdWalletCreateRequested`: emit `creating`; call `createHdWallet.execute`; emit `awaitingSeedConfirmation` with `pendingWallet` and `pendingMnemonic`; on error emit `error`
  - `_onWalletRestoreRequested`: emit `creating`; call `restoreHdWallet.execute`; emit `loaded`; on error emit `error`
  - `_onSeedConfirmed`: emit `loaded` with `clearPendingWallet: true, clearPendingMnemonic: true`
  - `_onSeedViewRequested`: call `getSeed.execute`; if null emit `error`; if found emit `awaitingSeedConfirmation` with `pendingMnemonic`

- [x] 5.2 Create `bloc/address/address_state.dart`
  - `AddressStatus` enum: `initial, loading, loaded, generating, error`
  - `AddressState` final class: `addresses`, `status`, `lastGenerated?`, `errorMessage?`
  - `copyWith` with `clearLastGenerated` and `clearErrorMessage` bool flags

- [x] 5.2 Create `bloc/address/address_event.dart`
  - `sealed class AddressEvent`
  - `AddressListRequested({required Wallet wallet})`
  - `AddressGenerateRequested({required Wallet wallet, required AddressType type})`

- [x] 5.2 Create `bloc/address/address_bloc.dart`
  - Constructor: `({required GetAddressesUseCase getAddresses, required GenerateAddressUseCase generateAddress})`
  - `_onAddressListRequested`: emit `loading`; call `getAddresses.execute(wallet)`; emit `loaded`; on error emit `error`
  - `_onAddressGenerateRequested`: guard — if `state.status == AddressStatus.generating` return; emit `generating`; call `generateAddress.execute`; append to `addresses`; emit `loaded` with `lastGenerated`; on error emit `error`

- [x] 5.3 Create `di/wallet_scope.dart`
  - `WalletScopeBlocFactory` final class
    - Creates all use cases in constructor initializer list from injected repos/services
    - `WalletBloc walletBloc()` — creates new instance wired to use cases
    - `AddressBloc addressBloc()` — creates new instance wired to use cases
  - `WalletScope` StatefulWidget (not InheritedWidget) with `_WalletScopeState`
    - `_InheritedWalletScope` is the internal InheritedWidget that exposes the factory
    - `static WalletScopeBlocFactory of(BuildContext context)` — throws `StateError` if absent
    - `updateShouldNotify` compares factory identity with `identical()`

- [x] 5.X Run `flutter analyze --fatal-infos --fatal-warnings` — zero issues

---

## Stop Conditions

- Architecture deviation from the plan
- `flutter analyze` reports any error or warning that cannot be trivially fixed
- Any blocker requiring a design decision not covered by the plan
- Batch complete (all checklist items done and analyze passes)

---

## Acceptance

- `HdWalletCreateRequested` causes `WalletBloc` to transition through `creating` → `awaitingSeedConfirmation` with `pendingMnemonic` non-null.
- `SeedConfirmed` causes `WalletBloc` to emit `loaded` with `pendingMnemonic == null`.
- `AddressGenerateRequested` causes `AddressBloc` to set `lastGenerated` with the correct `derivationPath` (non-null for HD, null for Node).
- A second `AddressGenerateRequested` while `status == generating` is ignored.
- `WalletScope.of(context)` returns `WalletScopeBlocFactory` without null assertion.
- `flutter analyze --fatal-infos --fatal-warnings` exits clean.
