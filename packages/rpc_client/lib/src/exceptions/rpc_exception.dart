class RpcException implements Exception {
  final String method;
  final Map<String, Object?> error;

  int? get code => error['code'] as int?;

  const RpcException(this.method, this.error);

  @override
  String toString() => 'RpcException[$method](${code ?? '?'}): ${error['message']}';
}

/// Thrown when the Bitcoin Core node is not reachable (connection refused,
/// network timeout, or host unreachable).
final class RpcNodeUnreachableException implements Exception {
  final String method;

  const RpcNodeUnreachableException(this.method);

  @override
  String toString() => 'RpcNodeUnreachableException[$method]: node is not reachable';
}
