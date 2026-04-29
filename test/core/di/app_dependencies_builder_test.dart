import 'package:bitcoin_wallet/core/config/config.dart';
import 'package:bitcoin_wallet/core/di/app_dependencies_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:shared_kernel/shared_kernel.dart';

void main() {
  test('uses app environment RPC values when building dependencies', () {
    const environment = AppEnvironment(
      rpc: RpcEnvironment(
        scheme: 'http',
        host: '10.0.0.5',
        port: 19001,
        user: 'alice',
        password: 'secret',
      ),
      network: BitcoinNetwork.regtest,
    );
    String? capturedUrl;
    String? capturedUser;
    String? capturedPassword;
    bool builderCalled = false;
    Object? capturedError;

    AppDependenciesBuilder.create(
      environment: environment,
      rpcClientFactory:
          ({
            required String url,
            required String user,
            required String password,
          }) {
            capturedUrl = url;
            capturedUser = user;
            capturedPassword = password;

            return BitcoinRpcClient(
              url: url,
              user: user,
              password: password,
            );
          },
      builder: (_) {
        builderCalled = true;
      },
      onError: (error, _) {
        capturedError = error;
      },
    );

    expect(capturedUrl, equals('http://10.0.0.5:19001'));
    expect(capturedUser, equals('alice'));
    expect(capturedPassword, equals('secret'));
    expect(builderCalled, isTrue);
    expect(capturedError, isNull);
  });
}
