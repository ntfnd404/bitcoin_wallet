import 'package:bitcoin_wallet/core/config/configuration_error.dart';

final class RpcEnvironment {
  static const String schemeKey   = 'BTC_RPC_SCHEME';
  static const String hostKey     = 'BTC_RPC_HOST';
  static const String portKey     = 'BTC_RPC_PORT';
  static const String userKey     = 'BTC_RPC_USER';
  static const String passwordKey = 'BTC_RPC_PASSWORD';

  final String scheme;
  final String host;
  final int port;
  final String user;
  final String password;

  // Compile-time dart-define values. All String.fromEnvironment calls live
  // here so they are evaluated at compile time.
  static const String _schemeRaw   = String.fromEnvironment(schemeKey);
  static const String _hostRaw     = String.fromEnvironment(hostKey);
  static const String _portRaw     = String.fromEnvironment(portKey);
  static const String _userRaw     = String.fromEnvironment(userKey);
  static const String _passwordRaw = String.fromEnvironment(passwordKey);

  String get url => '$scheme://$host:$port';

  @override
  int get hashCode => Object.hash(scheme, host, port, user, password);

  const RpcEnvironment({
    required this.scheme,
    required this.host,
    required this.port,
    required this.user,
    required this.password,
  });

  static RpcEnvironment fromDartDefines() {
    final scheme   = _normalize(_schemeRaw);
    final host     = _normalize(_hostRaw);
    final portStr  = _normalize(_portRaw);
    final user     = _normalize(_userRaw);
    final password = _normalize(_passwordRaw);

    final missing = [
      if (scheme   == null) schemeKey,
      if (host     == null) hostKey,
      if (portStr  == null) portKey,
      if (user     == null) userKey,
      if (password == null) passwordKey,
    ];
    if (missing.isNotEmpty) {
      throw ConfigurationError(
        'Missing required RPC configuration keys: ${missing.join(', ')}. '
        'Run Flutter with --dart-define-from-file=config/<env>.env.',
      );
    }

    final port = int.tryParse(portStr!);
    if (port == null || port <= 0 || port > 65535) {
      throw ConfigurationError(
        'Invalid $portKey: "$portStr". '
        'Expected a positive integer between 1 and 65535. '
        'Run Flutter with --dart-define-from-file=config/<env>.env.',
      );
    }

    return RpcEnvironment(
      scheme:   scheme!,
      host:     host!,
      port:     port,
      user:     user!,
      password: password!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RpcEnvironment &&
      other.scheme   == scheme &&
      other.host     == host &&
      other.port     == port &&
      other.user     == user &&
      other.password == password;

  static String? _normalize(String? v) {
    final t = v?.trim();
    if (t == null || t.isEmpty) return null;

    return t;
  }
}
