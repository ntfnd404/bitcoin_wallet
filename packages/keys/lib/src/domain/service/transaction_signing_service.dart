import 'package:keys/src/domain/entity/signing_input.dart';
import 'package:keys/src/domain/entity/signing_output.dart';

/// Signs a raw Bitcoin transaction using locally held private keys.
///
/// Currently supports P2WPKH inputs only (native SegWit / BIP84).
/// All inputs must belong to P2WPKH-type UTXOs.
abstract interface class TransactionSigningService {
  /// Builds, signs, and serialises a P2WPKH transaction.
  ///
  /// Returns the complete signed transaction as a hex string, ready for
  /// `sendrawtransaction`.
  ///
  /// [bech32Hrp] is the human-readable part used to decode output addresses
  /// (e.g. `bcrt` for regtest, `tb` for testnet, `bc` for mainnet).
  String signP2wpkh({
    required List<SigningInput> inputs,
    required List<SigningOutput> outputs,
    required String bech32Hrp,
    int version = 2,
    int locktime = 0,
  });
}
