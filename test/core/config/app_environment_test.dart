import 'package:bitcoin_wallet/core/config/config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_kernel/shared_kernel.dart';

void main() {
  group('AppEnvironment.parseNetwork', () {
    test('parses regtest', () {
      expect(AppEnvironment.parseNetwork('regtest'), BitcoinNetwork.regtest);
    });

    test('parses testnet', () {
      expect(AppEnvironment.parseNetwork('testnet'), BitcoinNetwork.testnet);
    });

    test('parses mainnet', () {
      expect(AppEnvironment.parseNetwork('mainnet'), BitcoinNetwork.mainnet);
    });

    test('throws ConfigurationError for unknown value', () {
      expect(
        () => AppEnvironment.parseNetwork('unknown'),
        throwsA(isA<ConfigurationError>()),
      );
    });
  });

  group('AppEnvironment equality', () {
    const rpc = RpcEnvironment(
      scheme: 'http',
      host: '127.0.0.1',
      port: 18443,
      user: 'bitcoin',
      password: 'bitcoin',
    );

    test('two instances with same values are equal', () {
      const a = AppEnvironment(rpc: rpc, network: BitcoinNetwork.regtest);
      const b = AppEnvironment(rpc: rpc, network: BitcoinNetwork.regtest);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different network are not equal', () {
      const a = AppEnvironment(rpc: rpc, network: BitcoinNetwork.regtest);
      const b = AppEnvironment(rpc: rpc, network: BitcoinNetwork.testnet);

      expect(a, isNot(equals(b)));
    });
  });

  group('RpcEnvironment equality', () {
    test('two instances with same values are equal', () {
      const a = RpcEnvironment(
        scheme: 'http', host: '127.0.0.1', port: 18443,
        user: 'bitcoin', password: 'bitcoin',
      );
      const b = RpcEnvironment(
        scheme: 'http', host: '127.0.0.1', port: 18443,
        user: 'bitcoin', password: 'bitcoin',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('url getter returns correct value', () {
      const rpc = RpcEnvironment(
        scheme: 'http', host: '127.0.0.1', port: 18443,
        user: 'bitcoin', password: 'bitcoin',
      );

      expect(rpc.url, equals('http://127.0.0.1:18443'));
    });
  });
}
