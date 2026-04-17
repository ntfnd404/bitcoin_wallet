import 'package:rpc_client/rpc_client.dart';
import 'package:wallet/wallet.dart';

/// [WalletRemoteDataSource] backed by [BitcoinRpcClient].
final class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final BitcoinRpcClient _rpcClient;

  const WalletRemoteDataSourceImpl({required BitcoinRpcClient rpcClient}) : _rpcClient = rpcClient;

  @override
  Future<void> createWallet(String walletName) => _rpcClient.call('createwallet', [walletName]);
}
