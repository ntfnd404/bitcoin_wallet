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

1. Static fields
2. Final fields
3. Constructors (production first, then `@visibleForTesting`)
4. Private fields
5. Getters / computed properties
6. Public methods
7. Private methods

**Never** mix the order. Static before instance, public before private within each group.

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

---

## Widgets

- `StatefulWidget` lifecycle order: `initState` → `didUpdateWidget/didChangeDependencies` → `build` → `dispose`
- **Never** create private `_buildXxx` methods — extract reusable widgets as separate classes
- Arrow functions only for single-expression bodies
- **Always** use `const` constructors where possible

---

## Async

- **Always** check `isClosed` before `emit()` after async gaps in BLoC
- **Never** ignore Futures — use `unawaited()` if intentionally fire-and-forget
- **Always** cancel subscriptions in `dispose` / `close`
