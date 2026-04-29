final class ConfigurationError implements Exception {
  const ConfigurationError(this.message);

  final String message;

  @override
  String toString() => 'ConfigurationError: $message';
}
