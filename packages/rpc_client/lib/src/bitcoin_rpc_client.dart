import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

class BitcoinRpcClient {
  final String _baseUrl;
  final String _credentials;
  final http.Client _client;

  BitcoinRpcClient({
    required String url,
    required String user,
    required String password,
    http.Client? client,
  })  : _baseUrl = url,
        _credentials = base64Encode(utf8.encode('$user:$password')),
        _client = client ?? http.Client();

  /// Calls a Bitcoin Core JSON-RPC method.
  ///
  /// Returns the raw `result` value — may be a [Map], [List], [String],
  /// [int], [double], [bool], or `null` depending on the method.
  ///
  /// Specify [walletName] to route the request to a wallet-specific endpoint
  /// (`/wallet/<walletName>`), required for wallet methods such as
  /// `getnewaddress`, `getbalance`, etc.
  ///
  /// Throws [RpcException] if the node returns an error.
  Future<Object?> call(
    String method, [
    List<Object?> params = const [],
    String? walletName,
  ]) async {
    final url = walletName != null
        ? Uri.parse('$_baseUrl/wallet/$walletName')
        : Uri.parse(_baseUrl);

    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $_credentials',
      },
      body: jsonEncode({
        'jsonrpc': '1.0',
        'id': method,
        'method': method,
        'params': params,
      }),
    );
    log('RPC $method → ${response.statusCode}', name: 'bitcoin_rpc');
    final body = jsonDecode(response.body) as Map<String, Object?>;
    final error = body['error'];
    if (error != null) {
      throw RpcException(method, error as Map<String, Object?>);
    }
    return body['result'];
  }
}

class RpcException implements Exception {
  final String method;
  final Map<String, Object?> error;

  const RpcException(this.method, this.error);

  @override
  String toString() => 'RpcException[$method]: ${error['message']}';
}
