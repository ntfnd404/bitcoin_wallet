import 'package:address/src/application/address_generation_strategy.dart';
import 'package:address/src/domain/entity/address.dart';
import 'package:address/src/domain/repository/address_repository.dart';
import 'package:keys/keys.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/wallet.dart';

/// Address generation strategy for [WalletType.hd] wallets.
///
/// Derives the address locally via BIP32 and persists via [AddressRepository].
final class HdAddressGenerationStrategy implements AddressGenerationStrategy {
  final SeedRepository _seedRepository;
  final KeyDerivationService _keyDerivationService;
  final AddressRepository _addressRepository;

  const HdAddressGenerationStrategy({
    required SeedRepository seedRepository,
    required KeyDerivationService keyDerivationService,
    required AddressRepository addressRepository,
  }) : _seedRepository = seedRepository,
       _keyDerivationService = keyDerivationService,
       _addressRepository = addressRepository;

  @override
  bool supports(WalletType type) => type == WalletType.hd;

  @override
  Future<Address> generate(Wallet wallet, AddressType addressType) async {
    final mnemonic = await _seedRepository.getSeed(wallet.id);
    if (mnemonic == null) {
      throw StateError('No seed found for wallet ${wallet.id}');
    }
    final index = await _addressRepository.nextAddressIndex(wallet.id);
    final derived = _keyDerivationService.deriveAddress(
      mnemonic,
      addressType,
      index,
    );
    final address = Address(
      value: derived.value,
      type: derived.type,
      walletId: wallet.id,
      index: index,
      derivationPath: derived.derivationPath,
    );
    await _addressRepository.saveAddress(address);

    return address;
  }
}
