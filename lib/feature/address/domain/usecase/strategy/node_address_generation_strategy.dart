import 'package:bitcoin_wallet/feature/address/domain/usecase/strategy/address_generation_strategy.dart';
import 'package:domain/domain.dart';

/// Address generation strategy for [WalletType.node] wallets.
///
/// Delegates to Bitcoin Core RPC for the address value,
/// then persists via [AddressRepository].
final class NodeAddressGenerationStrategy implements AddressGenerationStrategy {
  final BitcoinCoreGateway _gateway;
  final AddressRepository _addressRepository;

  const NodeAddressGenerationStrategy({
    required BitcoinCoreGateway gateway,
    required AddressRepository addressRepository,
  })  : _gateway = gateway,
        _addressRepository = addressRepository;

  @override
  bool supports(WalletType type) => type == WalletType.node;

  @override
  Future<Address> generate(Wallet wallet, AddressType addressType) async {
    final value = await _gateway.generateAddress(wallet.name, addressType);
    final index = await _addressRepository.nextAddressIndex(wallet.id);
    final address = Address(
      value: value,
      type: addressType,
      walletId: wallet.id,
      index: index,
    );
    await _addressRepository.saveAddress(address);

    return address;
  }
}
