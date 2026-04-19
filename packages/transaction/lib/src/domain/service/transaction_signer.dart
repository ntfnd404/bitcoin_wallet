import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/value_object/signing_input.dart';

/// Signs a transaction using HD-wallet key material and returns raw hex.
///
/// Defined in the domain (DIP) — the concrete implementation lives in the app
/// layer and bridges the `keys` and `address` packages.
abstract interface class TransactionSigner {
  /// Builds, signs, and serialises a transaction.
  ///
  /// [walletId] — wallet whose seed is used for key derivation.
  /// [inputs] — UTXOs to spend (with derivation metadata for key derivation).
  /// [recipientAddress] — destination address (bech32 / base58).
  /// [amountSat] — amount to send to [recipientAddress].
  /// [changeAddress] — address for the change output (ignored if [changeSat] is zero).
  /// [changeSat] — change amount; [Satoshi.zero] means no change output.
  /// [bech32Hrp] — human-readable part used for address validation.
  ///
  /// Returns the signed transaction as a hex string.
  Future<String> sign({
    required String walletId,
    required List<SigningInput> inputs,
    required String recipientAddress,
    required Satoshi amountSat,
    required String changeAddress,
    required Satoshi changeSat,
    required String bech32Hrp,
  });
}
