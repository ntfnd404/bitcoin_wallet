import 'package:wallet/src/domain/entity/wallet.dart';
import 'package:wallet/src/domain/repository/node_wallet_repository.dart';

/// Creates a new Node wallet in Bitcoin Core and persists the metadata locally.
///
/// This use case is pure delegation — the repository already speaks wallet's
/// language (throws `WalletException` subtypes after Phase 3 boundary
/// wrapping). No try/catch is needed because there is no language to translate
/// and no recovery to perform here.
final class CreateNodeWalletUseCase {
  final NodeWalletRepository _nodeWalletRepository;

  const CreateNodeWalletUseCase({required NodeWalletRepository nodeWalletRepository})
    : _nodeWalletRepository = nodeWalletRepository;

  Future<NodeWallet> call(String name) => _nodeWalletRepository.createNodeWallet(name);
}
