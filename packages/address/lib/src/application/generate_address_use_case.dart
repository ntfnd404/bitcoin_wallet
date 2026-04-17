import 'package:address/src/application/address_generation_strategy.dart';
import 'package:address/src/domain/entity/address.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/wallet.dart';

/// Generates the next address of [type] for [wallet].
///
/// Delegates to the registered [AddressGenerationStrategy] that supports
/// [wallet.type]. New wallet types extend the system by registering a new
/// strategy — this use case never changes (Open/Closed Principle).
///
/// Throws [StateError] if no strategy is registered for [wallet.type].
final class GenerateAddressUseCase {
  final List<AddressGenerationStrategy> _strategies;

  const GenerateAddressUseCase({required List<AddressGenerationStrategy> strategies})
      : _strategies = strategies;

  Future<Address> call(Wallet wallet, AddressType type) {
    final strategy = _strategies.firstWhere(
      (s) => s.supports(wallet.type),
      orElse: () => throw StateError('No address generation strategy for wallet type ${wallet.type}'),
    );

    return strategy.generate(wallet, type);
  }
}
