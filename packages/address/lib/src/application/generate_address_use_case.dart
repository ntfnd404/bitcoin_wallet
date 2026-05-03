import 'package:address/src/application/address_generation_strategy.dart';
import 'package:address/src/domain/entity/address.dart';
import 'package:address/src/domain/exception/address_exception.dart';
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

  const GenerateAddressUseCase({required List<AddressGenerationStrategy> strategies}) : _strategies = strategies;

  Future<Address> call(Wallet wallet, AddressType type) async {
    try {
      final strategy = _strategies.firstWhere(
        (s) => s.supports(wallet),
        orElse: () => throw const AddressNoStrategyException(),
      );

      return await strategy.generate(wallet, type);
    } on AddressNoStrategyException {
      rethrow;
    } catch (e, stack) {
      Error.throwWithStackTrace(const AddressGenerationException(), stack);
    }
  }
}
