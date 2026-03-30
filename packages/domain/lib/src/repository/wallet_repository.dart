import '../entity/address.dart';
import '../entity/address_type.dart';
import '../entity/wallet.dart';

/// Base wallet operations shared by both Node and HD wallet implementations.
abstract interface class WalletRepository {
  /// Returns all wallets managed by this repository.
  Future<List<Wallet>> getWallets();

  /// Generates the next address of [type] for [wallet].
  Future<Address> generateAddress(Wallet wallet, AddressType type);

  /// Returns all addresses previously generated for [wallet].
  Future<List<Address>> getAddresses(Wallet wallet);
}
