# ui_kit

## Purpose

Shared Flutter design-system package. Intended to house design tokens (colours,
spacing), typography styles, and the app theme. Currently in an empty state:
all exports are commented out pending the design-system build-out.

## Public API

Barrel: `package:ui_kit/ui_kit.dart`

The barrel currently exports nothing. All entries are commented out:

```
// Tokens
// export 'src/tokens/app_colors.dart';
// export 'src/tokens/app_spacing.dart';

// Typography
// export 'src/typography/app_text_styles.dart';

// Theme
// export 'src/theme/app_theme.dart';
```

Consumers must not import any `src/` path directly. Wait until symbols are
uncommented and promoted to the barrel before using them.

## Dependencies

Workspace packages: none.
Third-party: none.
SDK: Flutter SDK.

## When to add here

Add a symbol only when it is a shared design-system concern: colour token,
spacing token, typography style, or app theme. Never add domain knowledge,
business logic, feature-specific widgets, or BLoC code.

## Layer layout

```
lib/
  ui_kit.dart                 # barrel (currently empty)
  src/
    tokens/
      app_colors.dart         # not yet exported
      app_spacing.dart        # not yet exported
    typography/
      app_text_styles.dart    # not yet exported
    theme/
      app_theme.dart          # not yet exported
```
