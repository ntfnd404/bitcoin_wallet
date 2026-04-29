import 'package:bitcoin_wallet/core/config/app_environment.dart';
import 'package:bitcoin_wallet/core/config/rpc_environment.dart';

/// Loads [AppEnvironment] from compile-time dart-define values.
///
/// Run Flutter with `--dart-define-from-file=config/<env>.env`.
///
/// When web release needs runtime injection (e.g. window.parameters), split
/// this into environment_loader_native.dart + environment_loader_web.dart
/// and add:
///   export 'environment_loader_native.dart'
///       if (dart.library.js_interop) 'environment_loader_web.dart';
AppEnvironment loadEnvironment() => AppEnvironment(
  rpc: RpcEnvironment.fromDartDefines(),
  network: AppEnvironment.parseNetwork(
    const String.fromEnvironment('BTC_NETWORK', defaultValue: 'regtest'),
  ),
);
