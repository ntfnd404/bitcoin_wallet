import 'package:keys/keys.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/src/application/address_generation_strategy.dart';
import 'package:wallet/src/application/generate_address_use_case.dart';
import 'package:wallet/src/application/hd/create_hd_wallet_use_case.dart';
import 'package:wallet/src/application/hd/hd_address_generation_strategy.dart';
import 'package:wallet/src/application/hd/restore_hd_wallet_use_case.dart';
import 'package:wallet/src/application/node/create_node_wallet_use_case.dart';
import 'package:wallet/src/application/node/node_address_generation_strategy.dart';
import 'package:wallet/src/data/data_sources/wallet_local_data_source_impl.dart';
import 'package:wallet/src/data/repositories/address_mapper.dart';
import 'package:wallet/src/data/repositories/address_repository_impl.dart';
import 'package:wallet/src/data/repositories/wallet_mapper.dart';
import 'package:wallet/src/data/repositories/wallet_repository_impl.dart';
import 'package:wallet/src/domain/gateways/node_address_gateway.dart';
import 'package:wallet/src/domain/gateways/node_wallet_gateway.dart';
import 'package:wallet/src/domain/repositories/address_repository.dart';
import 'package:wallet/src/domain/repositories/wallet_repository.dart';

final class WalletAssembly {
  final WalletRepository walletRepository;
  final AddressRepository addressRepository;
  final GenerateAddressUseCase generateAddress;
  final CreateNodeWalletUseCase createNodeWallet;
  final CreateHdWalletUseCase createHdWallet;
  final RestoreHdWalletUseCase restoreHdWallet;

  factory WalletAssembly({
    required SecureStorage storage,
    required NodeWalletGateway remoteDataSource,
    required NodeAddressGateway addressRemoteDataSource,
    required Bip39Service bip39Service,
    required SeedRepository seedRepository,
    required KeyDerivationService keyDerivationService,
  }) {
    final walletRepository = WalletRepositoryImpl(
      localDataSource: WalletLocalDataSourceImpl(
        storage: storage,
        mapper: const WalletMapper(),
      ),
      remoteDataSource: remoteDataSource,
    );

    final addressRepository = AddressRepositoryImpl(
      storage: storage,
      mapper: const AddressMapper(),
    );

    final List<AddressGenerationStrategy> strategies = [
      HdAddressGenerationStrategy(
        seedRepository: seedRepository,
        keyDerivationService: keyDerivationService,
        addressRepository: addressRepository,
      ),
      NodeAddressGenerationStrategy(
        remoteDataSource: addressRemoteDataSource,
        addressRepository: addressRepository,
      ),
    ];

    return WalletAssembly._(
      walletRepository: walletRepository,
      addressRepository: addressRepository,
      generateAddress: GenerateAddressUseCase(strategies: strategies),
      createNodeWallet: CreateNodeWalletUseCase(nodeWalletRepository: walletRepository),
      createHdWallet: CreateHdWalletUseCase(
        bip39Service: bip39Service,
        seedRepository: seedRepository,
        hdWalletRepository: walletRepository,
      ),
      restoreHdWallet: RestoreHdWalletUseCase(
        bip39Service: bip39Service,
        seedRepository: seedRepository,
        hdWalletRepository: walletRepository,
      ),
    );
  }

  const WalletAssembly._({
    required this.walletRepository,
    required this.addressRepository,
    required this.generateAddress,
    required this.createNodeWallet,
    required this.createHdWallet,
    required this.restoreHdWallet,
  });
}
