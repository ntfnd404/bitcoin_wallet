/// Value object representing an amount in satoshis.
///
/// Satoshi is the smallest unit of Bitcoin (1 BTC = 100,000,000 satoshis).
/// Negative values are valid — outgoing transactions report negative amounts.
final class Satoshi {
  final int value;

  static const Satoshi zero = Satoshi(0);

  /// Formats as a BTC string with 8 decimal places.
  ///
  /// Example: Satoshi(100000000).btcDisplay == "1.00000000"
  String get btcDisplay => (value / 100000000).toStringAsFixed(8);

  @override
  int get hashCode => value.hashCode;

  const Satoshi(this.value);

  Satoshi operator +(Satoshi other) => Satoshi(value + other.value);

  Satoshi operator -(Satoshi other) => Satoshi(value - other.value);

  bool operator <(Satoshi other) => value < other.value;

  bool operator >(Satoshi other) => value > other.value;

  bool operator <=(Satoshi other) => value <= other.value;

  bool operator >=(Satoshi other) => value >= other.value;

  Satoshi abs() => Satoshi(value.abs());

  @override
  bool operator ==(Object other) => other is Satoshi && other.value == value;

  @override
  String toString() => '$value sat';
}
