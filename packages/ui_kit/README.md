# ui_kit

## Package type: Design system

Shared Flutter design-system package. Provides design tokens (colours,
spacing), typography styles, and the app theme. No business logic, no BLoC
code, no domain knowledge.

## Internal structure

**By UI concern.** Organised by what the token/style represents, not by layer.

```
lib/src/
  tokens/
    app_colors.dart         ← colour tokens
    app_spacing.dart        ← spacing scale
  typography/
    app_text_styles.dart    ← text style definitions
  theme/
    app_theme.dart          ← ThemeData assembly
```

### Why by UI concern

All files are Flutter-only design artifacts. There is no domain/application/data
split. Grouping by `tokens/`, `typography/`, `theme/` matches how designers
think about a design system.

## Public API

Barrel: `package:ui_kit/ui_kit.dart`
Currently empty — symbols are commented out pending the design-system build-out.
Do not import `src/` paths directly.

## Dependencies

Workspace packages: none.
Third-party: none.
SDK: Flutter SDK.
