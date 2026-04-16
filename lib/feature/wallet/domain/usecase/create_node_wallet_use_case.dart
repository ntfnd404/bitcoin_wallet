import 'package:domain/domain.dart';
import 'package:uuid/uuid.dart';

/// Creates a new Node wallet in Bitcoin Core and persists the metadata locally.
///
/// ID generation lives here (Application layer) — not in the repository.
/// [BitcoinCoreRemoteDataSource] is the domain Port; the RPC adapter is in data.
final class CreateNodeWalletUseCase {
  final BitcoinCoreRemoteDataSource _remoteDataSource;
  final WalletRepository _walletRepository;

  const CreateNodeWalletUseCase({
    required BitcoinCoreRemoteDataSource remoteDataSource,
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
