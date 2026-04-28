/// Root type for all domain failure hierarchies.
///
/// Extend with a sealed class per bounded context:
/// ```dart
/// sealed class WalletFailure extends AppFailure {}
/// ```
///
/// The [base] modifier prevents [implements] outside this library —
/// only [extends] is permitted from consumer packages.
abstract base class AppFailure {
  const AppFailure();
}
