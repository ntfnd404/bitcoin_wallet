import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

class BitcoinRpcClient {
  final String _url;
  final String _credentials;
  final http.Client _client;

  BitcoinRpcClient({
    required String url,
    required String user,
    required String password,
    http.Client? client,
  })  : _url = url,
        _credentials = base64Encode(utf8.encode('$user:$password')),
        _client = client ?? http.Client();

  Future<Map<String, Object?>> call(
    String method, [
    List<Object> params = const [],
  ]) async {
    final response = await _client.post(
      Uri.parse(_url),
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
    final result = body['result'] as Map<String, Object?>;

    return result;
  }
}

class RpcException implements Exception {
  final String method;
  final Map<String, Object?> error;

  const RpcException(this.method, this.error);

  @override
  String toString() => 'RpcException[$method]: ${error['message']}';
}
