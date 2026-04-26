import 'package:wallet/src/domain/entity/wallet.dart';
import 'package:wallet/src/domain/repository/node_wallet_repository.dart';

/// Creates a new Node wallet in Bitcoin Core and persists the metadata locally.
///
/// Delegates entirely to [NodeWalletRepository.createNodeWallet].
final class CreateNodeWalletUseCase {
  final NodeWalletRepository _nodeWalletRepository;

  const CreateNodeWalletUseCase({required NodeWalletRepository nodeWalletRepository})
    : _nodeWalletRepository = nodeWalletRepository;

  Future<NodeWallet> call(String name) => _nodeWalletRepository.createNodeWallet(name);
}
