import 'package:uuid/uuid.dart';
import 'package:wallet/src/domain/data_sources/wallet_remote_data_source.dart';
import 'package:wallet/src/domain/entity/wallet.dart';
import 'package:wallet/src/domain/entity/wallet_type.dart';
import 'package:wallet/src/domain/repository/wallet_repository.dart';

/// Creates a new Node wallet in Bitcoin Core and persists the metadata locally.
///
/// ID generation lives here (Application layer) — not in the repository.
final class CreateNodeWalletUseCase {
  final WalletRemoteDataSource _remoteDataSource;
  final WalletRepository _walletRepository;

  const CreateNodeWalletUseCase({
    required WalletRemoteDataSource remoteDataSource,
    required WalletRepository walletRepository,
  }) : _remoteDataSource = remoteDataSource,
       _walletRepository = walletRepository;

  Future<Wallet> call(String name) async {
    await _remoteDataSource.createWallet(name);
    final wallet = Wallet(
      id: const Uuid().v4(),
      name: name,
      type: WalletType.node,
      createdAt: DateTime.now().toUtc(),
    );
    await _walletRepository.saveWallet(wallet);

    return wallet;
  }
}
