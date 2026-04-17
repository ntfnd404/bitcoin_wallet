import 'package:address/address.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// [AddressRemoteDataSource] backed by [BitcoinRpcClient].
final class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  final BitcoinRpcClient _rpcClient;

  // Bitcoin Core RPC address type descriptors
  static const _rpcLegacy = 'legacy';
  static const _rpcWrappedSegwit = 'p2sh-segwit';
  static const _rpcNativeSegwit = 'bech32';
  static const _rpcTaproot = 'bech32m';

  const AddressRemoteDataSourceImpl({required BitcoinRpcClient rpcClient}) : _rpcClient = rpcClient;

  @override
  Future<String> generateAddress(String walletName, AddressType type) async {
    final result = await _rpcClient.call(
      'getnewaddress',
      ['', _rpcAddressType(type)],
      walletName,
    );

    return result as String;
  }

  String _rpcAddressType(AddressType type) => switch (type) {
    AddressType.legacy => _rpcLegacy,
    AddressType.wrappedSegwit => _rpcWrappedSegwit,
    AddressType.nativeSegwit => _rpcNativeSegwit,
    AddressType.taproot => _rpcTaproot,
  };
}
