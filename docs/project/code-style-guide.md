# Code Style Guide

Dart formatting and naming rules. Enforced by `flutter analyze --fatal-infos --fatal-warnings`.

---

## Formatting

- Page width: 120 characters
- **Always** use trailing commas in multi-line constructs
- **Always** use curly braces in `if`/`for`/`while` — never omit them
- **Always** use single quotes
- **Never** exceed 120 character line width

---

## Imports

**Always** use `package:` imports. **Never** use relative imports.

```dart
// ❌  import '../constants/app_constants.dart';
// ✅  import 'package:bitcoin_wallet/core/constants/app_constants.dart';
```

---

## Naming

| Construct | Convention | Example |
|-----------|-----------|---------|
| Classes / Interfaces | `UpperCamelCase` | `WalletRepository` |
| Implementations | `UpperCamelCase` + `Impl` | `WalletRepositoryImpl` |
| Enums | `UpperCamelCase` | `WalletStatus` |
| Enum values | `lowerCamelCase` | `WalletStatus.loading` |
| Methods / fields | `lowerCamelCase` | `generateAddress` |
| Private members | `_lowerCamelCase` | `_walletRepository` |
| Files | `snake_case.dart` | `wallet_repository.dart` |

---

## Class Member Ordering

Flutter framework convention (see `EdgeInsets`, `Container`, `TextButton`):

1. Constructors (production first, then named, factory, then `@visibleForTesting`)
2. Static const / static final fields
3. Instance fields — final, then late, then nullable (public before private within each)
4. Getters / computed properties
5. Public methods
6. Dispose / close
7. Private methods

```dart
// ❌
class Foo {
  static const _timeout = 30; // static before constructor — wrong
  const Foo();
  final String _id;
}

// ✅
class Foo {
  const Foo();
  static const _timeout = 30; // static after constructor
  final String _id;            // instance fields last
}
```

---

## Empty line before `return`

**Always** add a blank line before `return` when there is preceding code in the block.

```dart
// ❌
final result = compute();
return result;

// ✅
final result = compute();

return result;
```

Exception: arrow functions or `return` as the only statement.

---

## Null Safety

**Never** use `!` (null assertion). Always null-check with a local variable.

```dart
// ❌  final value = map['key']!;
// ✅
final value = map['key'];
if (value == null) return;
```

---

## Type Safety

**Never** use `dynamic`. Use `Object` (non-nullable) or `Object?` (nullable).

```dart
// ❌  Map<String, dynamic> result;
// ✅  Map<String, Object?> result;
```

**Always** declare return types. **Never** omit them.

---

## Variables

- **Always** use `final` for local variables that are not reassigned
- **Always** use `const` for compile-time constants
- **Never** use `var` when the type is not obvious from the right-hand side

---

## BLoC Classes

1. Final repository/service fields
2. Constructor with `super.initialState` + `on<>` registrations
3. Private fields (subscriptions)
4. Event handlers (private, `_onEventName`)

**Never** expose public fields or public methods on BLoC classes — all logic via events only.

**BLoC lifecycle and providers:**
- `BlocProvider(create: ...)` — BLoC is created inside the provider, lifecycle is managed by it
- `BlocProvider.value(value: ...)` — only for pre-created BLoCs with external lifecycle management (rare)
- **Never** pass BLoC as constructor parameter to a Widget — use `context.read<T>()` or `context.watch<T>()` instead
- **Never** do `BlocProvider(create: (_) => widget.bloc)` — this anti-pattern causes incorrect lifecycle management

```dart
// ❌ Anti-pattern: widget owns bloc, then provider tries to close it again
class MyScreen extends StatefulWidget {
  final MyBloc bloc;
  @override
  Widget build(BuildContext context) => BlocProvider(create: (_) => widget.bloc, ...);
}

// ✅ Correct: provider creates and owns the bloc
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => MyBlocFactory.create(...),
    child: ...,
  );
}

// ✅ Correct: screen reads from provider above
class MyScreen extends StatefulWidget {
  @override
  void initState() {
    context.read<MyBloc>().add(MyEvent());
  }
}
```

---

## Widgets

- `StatefulWidget` lifecycle order: `initState` → `didUpdateWidget/didChangeDependencies` → `build` → `dispose`
- **Never** create private `_buildXxx` methods — extract reusable widgets as separate classes
- Arrow functions only for single-expression bodies
- **Always** use `const` constructors where possible

---

## Use Cases

For use cases with a **single method**, name it `call` instead of `execute`. This allows calling the use case instance as a function.

```dart
// ❌ Legacy: execute method requires explicit invocation
class GetWalletsUseCase {
  Future<List<Wallet>> execute() => _repository.getWallets();
}
// Called as: await useCase.execute()

// ✅ Modern: call method is invoked like a function
class GetWalletsUseCase {
  Future<List<Wallet>> call() => _repository.getWallets();
}
// Called as: await useCase()
```

This convention improves readability for simple, single-purpose use cases.

---

## Feature Scopes

Feature-scoped DI (e.g., `WalletScope`, `AddressScope`) is the composition root for each Bounded Context.

**Pattern — Single BLoC per feature (session-level):**

All screens in a feature share the same session-level BLoC instance. This ensures consistent state across navigation and eliminates callback hell.

```dart
/// Feature-scoped DI entry point.
class WalletScope extends StatefulWidget {
  const WalletScope({required this.child});

  final Widget child;

  @override
  State<WalletScope> createState() => _WalletScopeState();
}

class _WalletScopeState extends State<WalletScope> {
  // Create all use cases in initState from AppDependencies
  late final GetWalletsUseCase _getWallets;
  late final CreateNodeWalletUseCase _createNodeWallet;
  late final CreateHdWalletUseCase _createHdWallet;
  late final RestoreHdWalletUseCase _restoreHdWallet;
  late final GetSeedUseCase _getSeed;

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);
    _getWallets = GetWalletsUseCase(walletRepository: dependencies.walletRepository);
    _createNodeWallet = CreateNodeWalletUseCase(...);
    _createHdWallet = CreateHdWalletUseCase(...);
    // ... initialize all use cases
  }

  @override
  Widget build(BuildContext context) => BlocProvider<WalletBloc>(
    create: (_) => WalletBloc(
      getWallets: _getWallets,
      createNodeWallet: _createNodeWallet,
      createHdWallet: _createHdWallet,
      restoreHdWallet: _restoreHdWallet,
      getSeed: _getSeed,
    ),
    child: widget.child,
  );
}
```

**Guidelines:**
- Scopes are wired in `app.dart` as nested StatefulWidgets
- **One session-level BLoC per feature** (e.g., `WalletBloc`, `AddressBloc`) created in `build()`
- BLoC is managed and closed automatically by `BlocProvider`
- Use cases are created once in `initState()` — reused by all screens in the feature
- All screens read from the same session BLoC using `context.read<WalletBloc>()`
- Never pass BLoCs as constructor params — always use `context.read<T>()` or `context.watch<T>()`
- Screens handle their own navigation via `BlocConsumer` / `BlocListener` on state changes
- No callbacks between Router and Screens — navigation is declarative (react to state)

---

## Async

- **Always** check `isClosed` before `emit()` after async gaps in BLoC
- **Never** ignore Futures — use `unawaited()` if intentionally fire-and-forget
- **Always** cancel subscriptions in `dispose` / `close`
