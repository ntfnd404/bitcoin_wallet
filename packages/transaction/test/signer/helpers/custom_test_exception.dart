/// Generic test exception used by signer tests to trigger the
/// `on Exception` translation path without coupling to any real
/// infrastructure exception (e.g. `KeysException`, `RpcException`).
final class CustomTestException implements Exception {
  const CustomTestException();
}
