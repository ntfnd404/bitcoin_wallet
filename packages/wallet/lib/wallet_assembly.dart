import 'package:keys/keys.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/src/application/hd/create_hd_wallet_use_case.dart';
import 'package:wallet/src/application/hd/restore_hd_wallet_use_case.dart';
import 'package:wallet/src/application/node/create_node_wallet_use_case.dart';
import 'package:wallet/src/data/wallet_local_data_source_impl.dart';
import 'package:wallet/src/data/wallet_mapper.dart';
import 'package:wallet/src/data/wallet_repository_impl.dart';
import 'package:wallet/src/domain/data_sources/wallet_remote_data_source.dart';
import 'package:wallet/src/domain/repository/wallet_repository.dart';

final class WalletAssembly {
  final WalletRepository walletRepository;
  final CreateNodeWalletUseCase createNodeWallet;
  final CreateHdWalletUseCase createHdWallet;
  final RestoreHdWalletUseCase restoreHdWallet;

  factory WalletAssembly({
    required SecureStorage storage,
    required WalletRemoteDataSource remoteDataSource,
    required Bip39Service bip39Service,
    required SeedRepository seedRepository,
  }) {
    final repository = WalletRepositoryImpl(
      localDataSource: WalletLocalDataSourceImpl(
        storage: storage,
        mapper: const WalletMapper(),
      ),
      remoteDataSource: remoteDataSource,
    );

    return WalletAssembly._(
      walletRepository: repository,
      createNodeWallet: CreateNodeWalletUseCase(nodeWalletRepository: repository),
      createHdWallet: CreateHdWalletUseCase(
        bip39Service: bip39Service,
        seedRepository: seedRepository,
        hdWalletRepository: repository,
      ),
      restoreHdWallet: RestoreHdWalletUseCase(
        bip39Service: bip39Service,
        seedRepository: seedRepository,
        hdWalletRepository: repository,
      ),
    );
  }

  const WalletAssembly._({
    required this.walletRepository,
    required this.createNodeWallet,
    required this.createHdWallet,
    required this.restoreHdWallet,
  });
}
