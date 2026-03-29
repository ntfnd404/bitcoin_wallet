# Flutter/Dart AI Guidelines

General Flutter and Dart development guidelines for AI agents working in this project.
These are broad, project-agnostic rules. Project-specific rules are in `conventions.md`.

---

## Interaction

- Propose code before writing — show snippets, wait for approval
- One task at a time — complete and confirm before proceeding
- Explain deviations from the plan explicitly

---

## Project Structure

- Feature-first: `lib/feature/<name>/` with `bloc/`, `di/`, `view/`
- Shared domain: `packages/domain/lib/src/entity/`, `repository/`, `service/`
- Data layer: `packages/data/lib/src/repository/`, `service/`
- Infra adapters: `packages/rpc_client/`, `packages/storage/`
- Design system: `packages/ui_kit/`
- Shared app code: `lib/common/widgets/`, `extensions/`, `utils/`

---

## SOLID & Architecture

- Single Responsibility: one class, one reason to change
- Dependency Inversion: depend on interfaces, not implementations
- No business logic in widgets or BLoC — put it in domain services
- No UI imports in domain or data layers

---

## Dart Best Practices

- Dart 3+, null safety everywhere
- **Never `!` operator** — always null-check with a local variable or pattern matching
- **Never `dynamic`** — use `Object` or `Object?`; JSON maps typed as `Map<String, Object?>`
- **Never `print`** — use `dart:developer` log
- Prefer `const` constructors
- Trailing commas in multi-line constructs
- Single quotes for strings

---

## Flutter Best Practices

- Prefer `StatelessWidget` over `StatefulWidget`
- No private `_buildXxx` methods — extract widgets instead
- `const` everywhere possible
- `build()` must be side-effect free
- Never call `setState` or `emit` from `build`

---

## State Management (BLoC)

- BLoC only — no Cubits
- Events are past-tense actions: `WalletCreated`, not `CreateWallet`
- Single freezed state class with enum status
- No business logic in event handlers — delegate to repositories/services

---

## Testing

- All Bitcoin-specific logic must have unit tests (BIP39, key derivation, coin selection)
- Use real SQLite/storage in integration tests — no mocks for persistence
- Test file mirrors source: `packages/data/lib/src/repository/foo.dart` → `packages/data/test/repository/foo_test.dart`

---

## Accessibility

- All interactive widgets must have semantic labels
- Support dynamic text scaling — no hardcoded font sizes
- Minimum touch target: 48×48 dp

---

## Packages

- Exact versions — no caret (`crypto: 3.0.7`, not `^3.0.7`)
- Sorted alphabetically in pubspec.yaml
- Verify platform support before adding a dependency
