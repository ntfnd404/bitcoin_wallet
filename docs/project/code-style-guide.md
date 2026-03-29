# Code Style Guide

Dart and Flutter code style rules for this project.
Enforced by `flutter analyze` + DCM. Agents follow these rules strictly.

---

## Formatting

- Page width: 120 characters
- Trailing commas in all multi-line constructs (function calls, parameters, collections)
- Curly braces in all `if`/`for`/`while` — even single-line bodies
- Single quotes for all strings

---

## Naming

| Construct | Convention | Example |
|-----------|-----------|---------|
| Classes | `UpperCamelCase` | `WalletRepository` |
| Interfaces | `UpperCamelCase` (no `I` prefix) | `WalletRepository` |
| Implementations | `UpperCamelCase` + `Impl` suffix | `WalletRepositoryImpl` |
| Enums | `UpperCamelCase` | `WalletStatus` |
| Enum values | `lowerCamelCase` | `WalletStatus.loading` |
| Methods/fields | `lowerCamelCase` | `generateAddress` |
| Private members | `_lowerCamelCase` | `_walletRepository` |
| Constants | `lowerCamelCase` | `rpcUrl` |
| Files | `snake_case.dart` | `wallet_repository.dart` |

---

## Class Member Ordering

1. Static fields
2. Final fields
3. Constructors (production first, then `@visibleForTesting`)
4. Private fields
5. Getters / computed properties
6. Public methods
7. Private methods

---

## BLoC Classes

1. Final repository/service fields
2. Constructor with `super.initialState` and `on<>` registrations
3. Private fields (subscriptions)
4. Event handler methods (private, `_onEventName`)

Event names: past-tense user actions — `WalletListRequested`, not `LoadWallets`.

---

## Widgets

Lifecycle order in `StatefulWidget`:
1. `initState`
2. `didUpdateWidget` / `didChangeDependencies`
3. `build`
4. `dispose`
5. Custom private methods after lifecycle

- Arrow functions only for single-expression bodies
- Extract reusable pieces as separate widget classes (never `_buildXxx` methods)

---

## Repositories

```dart
abstract interface class FooRepository {
  /// Doc comment on every method.
  Future<Foo> getFoo(String id);
}

class FooRepositoryImpl implements FooRepository {
  const FooRepositoryImpl({required FooApiClient client}) : _client = client;
  final FooApiClient _client;

  @override
  Future<Foo> getFoo(String id) async { ... }
}
```

---

## Null Safety

```dart
// ❌ Never
final value = map['key']!;

// ✅ Always
final value = map['key'];
if (value == null) return;
```

---

## Type Safety — no `dynamic`

Never use `dynamic`. Use `Object` (non-nullable) or `Object?` (nullable) instead.

```dart
// ❌ Never
Map<String, dynamic> result;
List<dynamic> params;

// ✅ Always
Map<String, Object?> result;  // JSON values can be null
List<Object> params;          // RPC params are non-null
```

When working with JSON (`jsonDecode`), cast explicitly to `Map<String, Object?>`.
Values accessed from such a map are `Object?` — null-check or cast before use.

---

## Empty line before `return`

Always add an empty line before `return` when there is preceding code in the block.
This visually separates the result from the logic that produces it.

```dart
// ❌ Never
final result = body['result'] as Map<String, Object?>;
return result;

// ✅ Always
final result = body['result'] as Map<String, Object?>;

return result;
```

Exception: a single-expression function body (arrow `=>`) or a `return` that is the only statement in the block does not need an empty line.

---

## Dependencies (pubspec.yaml)

- Exact versions: `crypto: 3.0.7` not `^3.0.7`
- Alphabetical order within `dependencies` and `dev_dependencies`
- Confirm transitive version via `dart pub deps` before pinning
