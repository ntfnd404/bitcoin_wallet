import 'dart:typed_data';

import 'package:keys/src/data/crypto/ecdsa.dart';
import 'package:keys/src/data/crypto/hash_utils.dart';
import 'package:keys/src/data/crypto/tx_builder.dart';
import 'package:keys/src/domain/entity/signing_input.dart';
import 'package:keys/src/domain/entity/signing_output.dart';
import 'package:keys/src/domain/service/transaction_signing_service.dart';

/// P2WPKH transaction signing using BIP143 sighash + ECDSA/secp256k1.
///
/// All inputs are expected to be native SegWit P2WPKH outputs (BIP84).
/// Signature is DER-encoded with SIGHASH_ALL (0x01) appended.
final class TransactionSigningServiceImpl implements TransactionSigningService {
  const TransactionSigningServiceImpl();

  @override
  String signP2wpkh({
    required List<SigningInput> inputs,
    required List<SigningOutput> outputs,
    required String bech32Hrp,
    int version = 2,
    int locktime = 0,
  }) {
    if (inputs.isEmpty) throw ArgumentError('inputs must not be empty');
    if (outputs.isEmpty) throw ArgumentError('outputs must not be empty');

    // Build sighash inputs — scriptCode for P2WPKH uses the scriptPubKey form
    final sighashInputs = inputs
        .map(
          (inp) => SighashInput(
            prevTxid: inp.txid,
            prevVout: inp.vout,
            amountSat: inp.amountSat.value,
            scriptCode: _p2wpkhScriptCode(inp.publicKey),
          ),
        )
        .toList();

    // Build sighash outputs — convert addresses to scriptPubKeys
    final sighashOutputs = outputs.map((out) {
      final script = p2wpkhScriptFromAddress(out.address, bech32Hrp);
      if (script == null) {
        throw ArgumentError('Cannot decode address: ${out.address}');
      }

      return SighashOutput(amountSat: out.amountSat.value, scriptPubKey: script);
    }).toList();

    // Sign each input
    final signedInputs = <SignedInput>[];
    for (var i = 0; i < inputs.length; i++) {
      final inp = inputs[i];

      final sighash = bip143Sighash(
        inputIndex: i,
        inputs: sighashInputs,
        outputs: sighashOutputs,
        version: version,
        locktime: locktime,
      );

      final derSig = ecdsaSign(inp.privateKey, sighash);
      final pubKey = inp.publicKey;

      signedInputs.add(
        SignedInput(
          prevTxid: inp.txid,
          prevVout: inp.vout,
          sequence: sighashInputs[i].sequence,
          witness: [derSig, pubKey],
        ),
      );
    }

    return serializeSegwitTx(
      inputs: signedInputs,
      outputs: sighashOutputs,
      version: version,
      locktime: locktime,
    );
  }

  /// P2WPKH scriptCode: OP_DUP OP_HASH160 PUSH20 `<keyhash>` OP_EQUALVERIFY OP_CHECKSIG
  ///
  /// This is the scriptCode used in BIP143 sighash preimage, not the output's
  /// actual scriptPubKey (which is just OP_0 PUSH20 `<keyhash>`).
  static Uint8List _p2wpkhScriptCode(Uint8List compressedPubKey) {
    final keyHash = hash160(compressedPubKey);

    // 76 a9 14 <20 bytes> 88 ac
    return Uint8List.fromList([
      0x76, // OP_DUP
      0xa9, // OP_HASH160
      0x14, // PUSH 20 bytes
      ...keyHash,
      0x88, // OP_EQUALVERIFY
      0xac, // OP_CHECKSIG
    ]);
  }
}
