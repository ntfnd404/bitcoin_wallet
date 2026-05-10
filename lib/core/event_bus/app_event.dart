/// Root type for all application-level events.
///
/// Extend via [sealed] subclasses grouped by domain area:
///
/// ```dart
/// sealed class WalletEvent extends AppEvent {}
/// final class WalletCreated extends WalletEvent { ... }
/// ```
///
/// Subclasses must use `extends`, not `implements`.
/// The `base` modifier prevents arbitrary implementations outside
/// this library, keeping the event hierarchy intentional.
abstract base class AppEvent {
  const AppEvent();
}
