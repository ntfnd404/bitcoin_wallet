import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/wallet.dart';

/// Generates the next address of [type] for [wallet].
///
/// Delegates to the registered [AddressGenerationStrategy] that supports
/// [wallet]. New wallet types extend the system by registering a new
/// strategy — this use case never changes (Open/Closed Principle).
///
/// Throws [AddressNoStrategyException] if no strategy is registered for [wallet].
/// Throws [AddressGenerationException] if the strategy itself fails.
final class GenerateAddressUseCase {
  final List<AddressGenerationStrategy> _strategies;

  const GenerateAddressUseCase({required this._strategies});

  // Strategies and AddressRepositoryImpl already throw AddressException
  // subtypes — nothing to translate here. Programmer errors (TypeError,
  // RangeError, etc.) propagate naturally to the zone error handler and
  // must NOT be masked as AddressGenerationException.
  Future<Address> call(Wallet wallet, AddressType type) {
    final strategy = _strategies.firstWhere(
      (s) => s.supports(wallet),
      orElse: () => throw const AddressNoStrategyException(),
    );

    return strategy.generate(wallet, type);
  }
}
