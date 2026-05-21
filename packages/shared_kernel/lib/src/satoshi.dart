/// Value object representing an amount in satoshis.
///
/// Satoshi is the smallest unit of Bitcoin (1 BTC = 100,000,000 satoshis).
/// Negative values are valid — outgoing transactions report negative amounts.
final class Satoshi {
  static const Satoshi zero = Satoshi(0);

  final int value;

  // 1 BTC = 100,000,000 satoshis (10^8)
  static const int _satoshisPerBtc = 100000000;

  /// BTC amount as a double (for RPC calls and arithmetic).
  ///
  /// Example: Satoshi(100000).btcAmount == 0.001
  double get btcAmount => value / _satoshisPerBtc;

  /// Formats as a BTC string with 8 decimal places (for display).
  ///
  /// Example: Satoshi(100000000).btcDisplay == "1.00000000"
  String get btcDisplay => btcAmount.toStringAsFixed(8);

  @override
  int get hashCode => value.hashCode;

  const Satoshi(this.value);

  /// Converts a BTC amount (from RPC responses) to [Satoshi].
  ///
  /// Uses rounding to avoid floating-point precision errors.
  /// Example: Satoshi.fromBtc(0.001) == Satoshi(100000)
  static Satoshi fromBtc(num btc) => Satoshi((btc * _satoshisPerBtc).round());

  @override
  bool operator ==(Object other) => other is Satoshi && other.value == value;

  bool operator <(Satoshi other) => value < other.value;

  bool operator >(Satoshi other) => value > other.value;

  bool operator <=(Satoshi other) => value <= other.value;

  bool operator >=(Satoshi other) => value >= other.value;

  Satoshi operator +(Satoshi other) => Satoshi(value + other.value);

  Satoshi operator -(Satoshi other) => Satoshi(value - other.value);

  Satoshi abs() => Satoshi(value.abs());

  @override
  String toString() => '$value sat';
}
