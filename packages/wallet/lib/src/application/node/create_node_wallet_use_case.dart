import 'package:wallet/src/domain/entity/wallet.dart';
import 'package:wallet/src/domain/exception/wallet_exception.dart';
import 'package:wallet/src/domain/repository/node_wallet_repository.dart';

/// Creates a new Node wallet in Bitcoin Core and persists the metadata locally.
///
/// Throws [WalletStorageException] if the RPC call or local persistence fails.
final class CreateNodeWalletUseCase {
  final NodeWalletRepository _nodeWalletRepository;

  const CreateNodeWalletUseCase({required NodeWalletRepository nodeWalletRepository})
    : _nodeWalletRepository = nodeWalletRepository;

  Future<NodeWallet> call(String name) async {
    try {
      return await _nodeWalletRepository.createNodeWallet(name);
    } catch (e, stack) {
      Error.throwWithStackTrace(const WalletStorageException(), stack);
    }
  }
}
