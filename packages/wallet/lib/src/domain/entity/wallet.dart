part 'node_wallet.dart';
part 'hd_wallet.dart';

/// Base type for all wallet variants.
///
/// Use pattern matching to distinguish between subtypes:
/// ```dart
/// switch (wallet) {
///   NodeWallet() => ...,
///   HdWallet()   => ...,
/// }
/// ```
sealed class Wallet {
  final String id;
  final String name;
  final DateTime createdAt;

  const Wallet({
    required this.id,
    required this.name,
    required this.createdAt,
  });
}
