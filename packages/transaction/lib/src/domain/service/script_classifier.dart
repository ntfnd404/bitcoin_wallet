import 'package:transaction/src/domain/value_object/script_type.dart';

/// Classifies a raw scriptPubKey hex string into a [ScriptType].
abstract interface class ScriptClassifier {
  /// Returns the [ScriptType] for [scriptPubKeyHex].
  ///
  /// Never throws. Returns [ScriptType.unknown] for empty, malformed,
  /// or unrecognised input. Length is validated for all fixed-length types.
  ScriptType classify(String scriptPubKeyHex);
}

/// Default implementation using Bitcoin protocol byte-pattern rules.
final class DefaultScriptClassifier implements ScriptClassifier {
  const DefaultScriptClassifier();

  @override
  ScriptType classify(String scriptPubKeyHex) {
    final s = scriptPubKeyHex.toLowerCase();

    // P2PKH: OP_DUP OP_HASH160 <20> OP_EQUALVERIFY OP_CHECKSIG — 25 bytes (50 hex)
    if (s.length == 50 && s.startsWith('76a914') && s.endsWith('88ac')) {
      return ScriptType.p2pkh;
    }

    // P2SH: OP_HASH160 <20> OP_EQUAL — 23 bytes (46 hex)
    if (s.length == 46 && s.startsWith('a914') && s.endsWith('87')) {
      return ScriptType.p2sh;
    }

    // P2WPKH: OP_0 <20> — 22 bytes (44 hex)
    if (s.length == 44 && s.startsWith('0014')) {
      return ScriptType.p2wpkh;
    }

    // P2WSH: OP_0 <32> — 34 bytes (68 hex)
    if (s.length == 68 && s.startsWith('0020')) {
      return ScriptType.p2wsh;
    }

    // P2TR: OP_1 <32> — 34 bytes (68 hex)
    if (s.length == 68 && s.startsWith('5120')) {
      return ScriptType.p2tr;
    }

    // OP_RETURN: starts with 0x6a opcode
    if (s.length >= 2 && s.startsWith('6a')) {
      return ScriptType.opReturn;
    }

    return ScriptType.unknown;
  }
}
