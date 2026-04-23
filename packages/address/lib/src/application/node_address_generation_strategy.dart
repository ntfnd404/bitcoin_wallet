import 'package:address/src/application/address_generation_strategy.dart';
import 'package:address/src/domain/data_sources/address_remote_data_source.dart';
import 'package:address/src/domain/entity/address.dart';
import 'package:address/src/domain/repository/address_repository.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/wallet.dart';

/// Address generation strategy for [NodeWallet] wallets.
///
/// Delegates to Bitcoin Core RPC for the address value,
/// then persists via [AddressRepository].
final class NodeAddressGenerationStrategy implements AddressGenerationStrategy {
  final AddressRemoteDataSource _remoteDataSource;
  final AddressRepository _addressRepository;

  const NodeAddressGenerationStrategy({
    required AddressRemoteDataSource remoteDataSource,
    required AddressRepository addressRepository,
  }) : _remoteDataSource = remoteDataSource,
       _addressRepository = addressRepository;

  @override
  bool supports(Wallet wallet) => wallet is NodeWallet;

  @override
  Future<Address> generate(Wallet wallet, AddressType addressType) async {
    final value = await _remoteDataSource.generateAddress(wallet.name, addressType);
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
