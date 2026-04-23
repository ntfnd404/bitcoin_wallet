class RpcException implements Exception {
  final String method;
  final Map<String, Object?> error;

  int? get code => error['code'] as int?;

  const RpcException(this.method, this.error);

  @override
  String toString() => 'RpcException[$method](${code ?? '?'}): ${error['message']}';
}
