import 'package:transaction/src/domain/entity/utxo.dart';
import 'package:transaction/src/domain/gateway/utxo_gateway.dart';
import 'package:transaction/src/domain/repository/utxo_repository.dart';

/// [UtxoRepository] backed by [UtxoGateway].
///
/// UTXOs are never cached locally — always fresh from the node.
final class UtxoRepositoryImpl implements UtxoRepository {
  final UtxoGateway _remoteDataSource;

  const UtxoRepositoryImpl({
    required UtxoGateway remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Utxo>> getUtxos(String walletName) => _remoteDataSource.getUtxos(walletName);
}
