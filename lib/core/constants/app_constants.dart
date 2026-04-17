import 'package:shared_kernel/shared_kernel.dart';

abstract final class AppConstants {
  /// Active Bitcoin network. Change this one constant to switch networks.
  static const BitcoinNetwork network = BitcoinNetwork.regtest;
  static const String rpcUser = 'bitcoin';
  static const String rpcPassword = 'bitcoin';

  static String get rpcUrl => 'http://127.0.0.1:${network.rpcPort}';

  /// BIP44/49/84/86 account-level paths. Append `/index` at derivation time.
  static String get derivationPathLegacy => "m/44'/${network.coinType}'/0'/0";
  static String get derivationPathWrappedSegwit => "m/49'/${network.coinType}'/0'/0";
  static String get derivationPathNativeSegwit => "m/84'/${network.coinType}'/0'/0";
  static String get derivationPathTaproot => "m/86'/${network.coinType}'/0'/0";
}
