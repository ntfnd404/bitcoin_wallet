# action_bloc

## Package type: Shared utility

Extends `flutter_bloc` with a typed one-shot action stream for side-effects
(navigation, SnackBars, clipboard) that must not live in BLoC state. Used by
every feature BLoC in the app.

## Internal structure

**Flat.** All symbols are at the same abstraction level.

```
lib/src/
  action_bloc_listener.dart   ← ActionBlocListener widget
  action_bloc_mixin.dart      ← ActionBlocMixin<S, A> for BLoC classes
  action_bloc_observer.dart   ← ActionBlocObserver for debugging
  action_bloc_streamable.dart ← ActionBlocStreamable / ActionBlocObservable interfaces
```

### Why flat

Single-concern utility with no internal hierarchy. All files are at the same
abstraction level — no domain/application/data split applies.

## Public API

Barrel: `package:action_bloc/action_bloc.dart`

| Symbol | Kind | Description |
|---|---|---|
| `ActionBlocMixin<S, A>` | mixin | Adds `actionStream` + `emitAction` to a `Bloc` |
| `ActionBlocListener<B, S, A>` | widget | Listens to `actionStream` and calls `listener` |
| `ActionBlocConsumer<B, S, A>` | widget | Combines `BlocBuilder` + `ActionBlocListener` |
| `ActionBlocObserver` | class | `BlocObserver` that forwards actions to a callback |

## Dependencies

Workspace packages: none.
Third-party: `flutter_bloc`.
SDK: Flutter SDK.
