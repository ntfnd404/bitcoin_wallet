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
- **Always** use `BlocProvider(create: ...)` — BLoC is created inside the provider, lifecycle is auto-managed (auto-dispose)
- **Never** use `BlocProvider.value` — always `BlocProvider(create: ...)`
- **Never** pass BLoC as constructor parameter to a Widget — use `context.read<T>()` or `context.watch<T>()` instead
- **Never** do `BlocProvider(create: (_) => widget.bloc)` — this hands lifecycle to provider while BLoC was created externally
- BLoC instances are created via Scope factory: `SomeScope.newBloc(context)`

```dart
// ❌ Anti-pattern: BlocProvider.value with external lifecycle
class MyScope extends StatefulWidget {
  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,   // scope holds the instance — wrong
    child: ...,
  );
}

// ❌ Anti-pattern: widget owns bloc
class MyScreen extends StatefulWidget {
  final MyBloc bloc;
  @override
  Widget build(BuildContext context) => BlocProvider(create: (_) => widget.bloc, ...);
}

// ✅ Correct: BlocProvider(create:) via Scope factory, low in tree
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => MyScope.newBloc(context),
    child: const _MyView(),
  );
}
```

---

## Widgets

- `StatefulWidget` lifecycle order: `initState` → `didUpdateWidget/didChangeDependencies` → `build` → `dispose`
- **Never** create private `_buildXxx` methods — extract reusable widgets as separate classes
- Arrow functions only for single-expression bodies
- **Always** use `const` constructors where possible

### Accessing InheritedWidget in State

**Never** call `context.read<T>()`, `context.watch<T>()`, or any `InheritedWidget`-based lookup inside `initState` — the widget is not yet in the tree and the lookup will throw.

**Always** use `didChangeDependencies` with an `_initialized` guard for `late final` fields that depend on `InheritedWidget`:

```dart
class _MyState extends State<MyWidget> {
  late final MyDependency _dep;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    _dep = context.read<MyDependency>();
  }
}
```

The guard is mandatory when the field is `late final` — assigning it twice throws `LateInitializationError`. `didChangeDependencies` can be called multiple times (e.g., when an ancestor `InheritedWidget` updates).

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

Scope = composition root that **assembles dependencies** and **exposes a factory** for creating BLoC instances. Scope does NOT hold or own BLoC instances.

**Pattern — Scope provides factory, BlocProvider placed low in tree:**

```dart
/// Scope: assembles dependencies, exposes factory via InheritedWidget.
/// Placed HIGH in tree (e.g., in AppRouterDelegate).
class WalletListScope extends StatefulWidget {
  const WalletListScope({required this.child});
  final Widget child;

  /// Creates a new WalletListBloc with all dependencies wired.
  static WalletListBloc newBloc(BuildContext context) {
    final scope = context
        .getInheritedWidgetOfExactType<_InheritedWalletListScope>();
    if (scope == null) {
      throw StateError('WalletListScope not found in widget tree');
    }

    return scope.newBloc();
  }

  @override
  State<WalletListScope> createState() => _WalletListScopeState();
}

class _WalletListScopeState extends State<WalletListScope> {
  late final WalletRepository _walletRepository;
  bool _initialized = false;

  WalletListBloc _newBloc() => WalletListBloc(
    walletRepository: _walletRepository,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);
    _walletRepository = deps.walletRepository;
  }

  @override
  Widget build(BuildContext context) => _InheritedWalletListScope(
    newBloc: _newBloc,
    child: widget.child,
  );
}

class _InheritedWalletListScope extends InheritedWidget {
  const _InheritedWalletListScope({
    required this.newBloc,
    required super.child,
  });

  final WalletListBloc Function() newBloc;

  @override
  bool updateShouldNotify(_InheritedWalletListScope old) => false;
}
```

```dart
/// Screen: BlocProvider placed LOW in tree, near BlocBuilder.
/// BlocProvider(create:) auto-manages lifecycle (auto-dispose).
class WalletListScreen extends StatelessWidget {
  const WalletListScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<WalletListBloc>(
    create: (_) => WalletListScope.newBloc(context),
    child: const _WalletListView(),
  );
}
```

**Guidelines:**
- **Scope** = high in tree, assembles dependencies, exposes factory via static method + InheritedWidget
- **BlocProvider(create: ...)** = low in tree, near the screen/BlocBuilder. Auto-disposes BLoC
- **Never** use `BlocProvider.value` — always `BlocProvider(create: ...)`
- **Never** hold BLoC instances in Scope — Scope provides a way to CREATE them
- **One BLoC per flow** — no god-object BLoCs handling multiple flows
- All screens access BLoC via `context.read<T>()` or `context.watch<T>()`
- **Never** pass BLoCs as constructor params to widgets
- Screens navigate directly via `AppRouter` static methods — no callbacks up the tree
- **Never** read `AppScope.of(context)` in `initState` — use `didChangeDependencies` with `_initialized` guard
- Cross-flow communication via `AppEventBus`, not BLoC-to-BLoC subscription

---

## Navigation

The app uses **Navigator 2.0** via a custom `RouterDelegate` — no third-party routing packages.

**`AppRouterDelegate`** is the single routing entry point:
- Registered with `MaterialApp.router(routerDelegate: _delegate)`
- `build()` wraps `Navigator` with feature scopes (`WalletScope`, `AddressScope`) — this is the only way to place scopes **below `MaterialApp`** (so `MediaQuery`, `Theme`, `Localizations` are available) but **above `Navigator`** (so all pushed routes share the same BLoC instances)
- Imperative pushes use `AppRouter` static methods (`AppRouter.toWalletDetail(context, wallet)`)

```dart
final class AppRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => WalletScope(
    child: AddressScope(
      child: Navigator(key: navigatorKey, ...),
    ),
  );

  @override
  Future<void> setNewRoutePath(Object configuration) async {}
}
```

**`AppRouterDelegate` is created once** in `_AppState.initState()` — `RouterDelegate` must not be recreated on rebuild.

**Guidelines:**
- **Never** use `go_router` or other routing packages — use built-in Navigator 2.0
- Feature scopes belong in `AppRouterDelegate.build()`, not in `app.dart`
- `AppRouter` methods are the only navigation API visible to screens
- Screens **never** call `Navigator.push` directly — always go through `AppRouter`

---

## Async

- **Always** check `isClosed` before `emit()` after async gaps in BLoC
- **Never** ignore Futures — use `unawaited()` if intentionally fire-and-forget
- **Always** cancel subscriptions in `dispose` / `close`
