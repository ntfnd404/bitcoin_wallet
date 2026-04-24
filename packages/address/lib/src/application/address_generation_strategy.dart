import 'package:address/src/domain/entity/address.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/wallet.dart';

/// Strategy for generating addresses for one specific [Wallet] subtype.
///
/// New wallet types register a new strategy — [GenerateAddressUseCase]
/// never changes (Open/Closed Principle).
abstract interface class AddressGenerationStrategy {
  /// Returns `true` if this strategy handles [wallet].
  bool supports(Wallet wallet);

  /// Generates the next address of [addressType] for [wallet],
  /// persists it, and returns it.
  Future<Address> generate(Wallet wallet, AddressType addressType);
}
