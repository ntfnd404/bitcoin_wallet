# Code Style Guide

Dart formatting and naming rules. Enforced by `flutter analyze`.

---

## Formatting

- Page width: 120 characters
- Trailing commas in all multi-line constructs
- Curly braces in all `if`/`for`/`while`
- Single quotes

---

## Imports

Always `package:` imports. Relative imports are forbidden.

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

1. Static fields
2. Final fields
3. Constructors (production first, then `@visibleForTesting`)
4. Private fields
5. Getters / computed properties
6. Public methods
7. Private methods

---

## Empty line before `return`

Add a blank line before `return` when there is preceding code in the block.

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

```dart
// ❌  final value = map['key']!;
// ✅
final value = map['key'];
if (value == null) return;
```

---

## Type Safety — no `dynamic`

Use `Object` (non-nullable) or `Object?` (nullable). JSON maps = `Map<String, Object?>`.

```dart
// ❌  Map<String, dynamic> result;
// ✅  Map<String, Object?> result;
```

---

## BLoC Classes

1. Final repository/service fields
2. Constructor with `super.initialState` + `on<>` registrations
3. Private fields (subscriptions)
4. Event handlers (private, `_onEventName`)

---

## Widgets

`StatefulWidget` lifecycle order: `initState` → `didUpdateWidget/didChangeDependencies` → `build` → `dispose`.

- Arrow functions only for single-expression bodies.
- Extract reusable widgets as separate classes — never `_buildXxx` methods.
