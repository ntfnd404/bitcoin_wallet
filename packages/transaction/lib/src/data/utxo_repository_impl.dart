import 'package:transaction/src/domain/data_sources/utxo_remote_data_source.dart';
import 'package:transaction/src/domain/entity/utxo.dart';
import 'package:transaction/src/domain/repository/utxo_repository.dart';

/// [UtxoRepository] backed by [UtxoRemoteDataSource].
///
/// UTXOs are never cached locally — always fresh from the node.
final class UtxoRepositoryImpl implements UtxoRepository {
  final UtxoRemoteDataSource _remoteDataSource;

  const UtxoRepositoryImpl({
    required UtxoRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Utxo>> getUtxos(String walletName) => _remoteDataSource.getUtxos(walletName);
}
