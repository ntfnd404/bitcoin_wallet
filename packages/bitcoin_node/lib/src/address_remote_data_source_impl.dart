import 'package:address/address.dart';
import 'package:bitcoin_node/src/address_type_rpc.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// [AddressRemoteDataSource] backed by [BitcoinRpcClient].
final class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  final BitcoinRpcClient _rpcClient;

  const AddressRemoteDataSourceImpl({required BitcoinRpcClient rpcClient}) : _rpcClient = rpcClient;

  @override
  Future<String> generateAddress(String walletName, AddressType type) async {
    final result = await _rpcClient.call(
      'getnewaddress',
      ['', type.rpcAddressTypeParam],
      walletName,
    );

    return result as String;
  }
}
