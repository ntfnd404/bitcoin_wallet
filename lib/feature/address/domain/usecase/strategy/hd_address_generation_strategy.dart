import 'package:bitcoin_wallet/feature/address/domain/usecase/strategy/address_generation_strategy.dart';
import 'package:domain/domain.dart';

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
  })  : _seedRepository = seedRepository,
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
    final address = _keyDerivationService.deriveAddress(
      mnemonic,
      addressType,
      index,
      wallet.id,
    );
    await _addressRepository.saveAddress(address);

    return address;
  }
}
