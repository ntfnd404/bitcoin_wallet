final class ConfigurationError implements Exception {
  final String message;

  const ConfigurationError(this.message);

  @override
  String toString() => 'ConfigurationError: $message';
}
