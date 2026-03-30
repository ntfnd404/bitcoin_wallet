class RpcException implements Exception {
  final String method;
  final Map<String, Object?> error;

  const RpcException(this.method, this.error);

  @override
  String toString() => 'RpcException[$method]: ${error['message']}';
}
