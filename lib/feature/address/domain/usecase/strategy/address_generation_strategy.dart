import 'package:domain/domain.dart';

/// Strategy for generating addresses for one specific [WalletType].
///
/// New wallet types register a new strategy — [GenerateAddressUseCase]
/// never changes (Open/Closed Principle).
abstract interface class AddressGenerationStrategy {
  /// Returns `true` if this strategy handles [type].
  bool supports(WalletType type);

  /// Generates the next address of [addressType] for [wallet],
  /// persists it, and returns it.
  Future<Address> generate(Wallet wallet, AddressType addressType);
}
