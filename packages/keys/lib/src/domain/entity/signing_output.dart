import 'package:shared_kernel/shared_kernel.dart';

/// A transaction output: recipient address + amount.
final class SigningOutput {
  /// Bitcoin address string (bech32 P2WPKH for regtest).
  final String address;

  /// Amount in satoshis.
  final Satoshi amountSat;

  const SigningOutput({required this.address, required this.amountSat});
}
