import 'package:bitcoin_wallet/core/config/configuration_error.dart';
import 'package:bitcoin_wallet/core/config/rpc_environment.dart';
import 'package:shared_kernel/shared_kernel.dart';

final class AppEnvironment {
  final RpcEnvironment rpc;
  final BitcoinNetwork network;

  static const String _networkKey = 'BTC_NETWORK';

  @override
  int get hashCode => Object.hash(rpc, network);

  const AppEnvironment({required this.rpc, required this.network});

  static BitcoinNetwork parseNetwork(String raw) => switch (raw) {
    'mainnet' => BitcoinNetwork.mainnet,
    'testnet' => BitcoinNetwork.testnet,
    'regtest' => BitcoinNetwork.regtest,
    _ => throw ConfigurationError(
      'Invalid $_networkKey: "$raw". '
      'Expected mainnet, testnet, or regtest. '
      'Run Flutter with --dart-define-from-file=config/<env>.env.',
    ),
  };

  @override
  bool operator ==(Object other) =>
      other is AppEnvironment &&
      other.rpc     == rpc &&
      other.network == network;
}
