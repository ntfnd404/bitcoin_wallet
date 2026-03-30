import '../entity/address.dart';
import '../entity/address_type.dart';
import '../entity/mnemonic.dart';
import '../entity/wallet.dart';

abstract interface class WalletRepository {
  /// Returns all wallets persisted on this device.
  Future<List<Wallet>> getWallets();

  /// Creates a new Node Wallet via Bitcoin Core RPC `createwallet`.
  ///
  /// Throws [UnsupportedError] if called on an HD-only implementation.
  Future<Wallet> createNodeWallet(String name);

  /// Creates a new HD Wallet, generates a BIP39 mnemonic, stores the seed,
  /// and returns both the wallet metadata and the mnemonic.
  ///
  /// [wordCount] must be 12 or 24.
  /// Throws [UnsupportedError] if called on a Node-only implementation.
  Future<(Wallet, Mnemonic)> createHDWallet(String name, {int wordCount = 12});

  /// Restores an HD Wallet from an existing [mnemonic] after BIP39 validation.
  ///
  /// Throws [ArgumentError] if [mnemonic] fails BIP39 checksum validation.
  /// Throws [UnsupportedError] if called on a Node-only implementation.
  Future<Wallet> restoreHDWallet(String name, Mnemonic mnemonic);

  /// Generates the next address of [type] for [wallet].
  ///
  /// For Node Wallet: calls RPC `getnewaddress`.
  /// For HD Wallet: derives the key at the next unused index.
  Future<Address> generateAddress(Wallet wallet, AddressType type);

  /// Returns all addresses previously generated for [wallet].
  Future<List<Address>> getAddresses(Wallet wallet);
}
