# Flutter/Dart Guidelines

Flutter-specific patterns for this project. Architecture rules and prohibited constructs
are in `conventions.md`. Formatting rules are in `code-style-guide.md`.

---

## Flutter Widgets

- Prefer `StatelessWidget` over `StatefulWidget`
- `const` everywhere possible (constructors, widgets, lists)
- `build()` must be side-effect free — never call `setState` or `emit` from `build`
- Extract reusable widgets as separate classes — never `_buildXxx` private methods

---

## Design Patterns in use

| Pattern | Where |
|---------|-------|
| **Repository** | `domain/repository/` interfaces + `data/repository/` impls |
| **Adapter** | `rpc_client/` (Bitcoin Core RPC), `storage/` (secure storage) |
| **Factory** | `WalletScope` + `BlocFactory` — DI without service locator |
| **Observer** | BLoC streams — UI reacts to state changes |
| **Strategy** | Coin selection algorithms (Phase 5) |

---

## Testing

- Mirror source structure: `packages/data/lib/src/foo.dart` → `packages/data/test/foo_test.dart`
- Use real storage in integration tests — no mocks for persistence layers

---

## Accessibility

- All interactive widgets must have semantic labels
- Support dynamic text scaling — no hardcoded font sizes
- Minimum touch target: 48×48 dp
