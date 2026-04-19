import 'package:shared_kernel/shared_kernel.dart';

/// Parameter for a single UTXO to be signed.
///
/// Carries UTXO data but NOT the private key —
/// that is derived internally from [walletId] + [derivationIndex].
final class SigningInputParam {
  final String txid;
  final int vout;
  final Satoshi amountSat;
  final AddressType type;
  final int derivationIndex;

  const SigningInputParam({
    required this.txid,
    required this.vout,
    required this.amountSat,
    required this.type,
    required this.derivationIndex,
  });
}
