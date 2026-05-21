import 'package:bitcoin_node/src/address/address_type_rpc.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/wallet.dart';

/// [NodeAddressGateway] backed by [BitcoinRpcClient].
///
/// Wraps RPC / network / parse failures as [AddressGenerationException].
final class NodeAddressGatewayImpl implements NodeAddressGateway {
  final BitcoinRpcClient _rpcClient;

  const NodeAddressGatewayImpl({required this._rpcClient});

  @override
  Future<String> generateAddress(String walletName, AddressType type) async {
    try {
      final result = await _rpcClient.call(
        'getnewaddress',
        ['', type.rpcAddressTypeParam],
        walletName,
      );

      return result as String;
    } catch (_, stack) {
      Error.throwWithStackTrace(const AddressGenerationException(), stack);
    }
  }
}
