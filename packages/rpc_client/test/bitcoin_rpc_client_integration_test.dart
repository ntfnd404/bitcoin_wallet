/// Integration test — requires a live Bitcoin Core regtest node.
///
/// Run with:
///   dart test packages/rpc_client/test/bitcoin_rpc_client_integration_test.dart
///
/// Prerequisites:
///   make btc-up && make btc-wallet-ready
library;

import 'package:rpc_client/rpc_client.dart';
import 'package:test/test.dart';

void main() {
  late BitcoinRpcClient client;

  setUp(() {
    client = BitcoinRpcClient(
      url: 'http://127.0.0.1:18443',
      user: 'bitcoin',
      password: 'bitcoin',
    );
  });

  group('BitcoinRpcClient', () {
    test('getblockchaininfo returns chain: regtest', () async {
      final result = await client.call('getblockchaininfo');

      expect(result['chain'], equals('regtest'));
    });

    test('unknown method throws RpcException', () async {
      expect(
        () => client.call('nonexistentmethod'),
        throwsA(isA<RpcException>()),
      );
    });

    test('getnetworkinfo returns version', () async {
      final result = await client.call('getnetworkinfo');

      expect(result['version'], isA<int>());
    });
  });
}
