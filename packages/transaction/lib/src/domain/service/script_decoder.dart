/// Decodes raw Bitcoin script hex to human-readable assembly notation.
abstract interface class ScriptDecoder {
  /// Decodes a scriptPubKey or scriptSig hex string to asm notation.
  ///
  /// Returns an empty string for an empty [scriptHex].
  /// Returns [scriptHex] unchanged for unrecognised or malformed input.
  /// Never throws.
  String decode(String scriptHex);

  /// Decodes a SegWit witness stack to asm notation.
  ///
  /// Items are joined space-separated in order.
  /// Returns an empty string for an empty [witness] list.
  /// Never throws.
  String decodeWitness(List<String> witness);
}

/// Default implementation covering the six canonical script types plus
/// push-data scriptSig decoding as a fallback.
final class DefaultScriptDecoder implements ScriptDecoder {
  const DefaultScriptDecoder();

  @override
  String decode(String scriptHex) {
    if (scriptHex.isEmpty) return '';

    final s = scriptHex.toLowerCase();

    // P2PKH: OP_DUP OP_HASH160 <20-byte-hash> OP_EQUALVERIFY OP_CHECKSIG
    if (s.length == 50 && s.startsWith('76a914') && s.endsWith('88ac')) {
      return 'OP_DUP OP_HASH160 ${s.substring(6, 46)} OP_EQUALVERIFY OP_CHECKSIG';
    }

    // P2SH: OP_HASH160 <20-byte-hash> OP_EQUAL
    if (s.length == 46 && s.startsWith('a914') && s.endsWith('87')) {
      return 'OP_HASH160 ${s.substring(4, 44)} OP_EQUAL';
    }

    // P2WPKH: OP_0 <20-byte-hash>
    if (s.length == 44 && s.startsWith('0014')) {
      return 'OP_0 ${s.substring(4)}';
    }

    // P2WSH: OP_0 <32-byte-hash>
    if (s.length == 68 && s.startsWith('0020')) {
      return 'OP_0 ${s.substring(4)}';
    }

    // P2TR: OP_1 <32-byte-tweaked-pubkey>
    if (s.length == 68 && s.startsWith('5120')) {
      return 'OP_1 ${s.substring(4)}';
    }

    // OP_RETURN: skip the push-length byte after the opcode to expose raw data
    if (s.startsWith('6a')) {
      if (s.length == 2) return 'OP_RETURN';
      final data = s.length > 4 ? s.substring(4) : '';

      return data.isEmpty ? 'OP_RETURN' : 'OP_RETURN $data';
    }

    // Fallback: try push-data decoding (standard scriptSig format)
    return _decodePushData(s);
  }

  @override
  String decodeWitness(List<String> witness) {
    if (witness.isEmpty) return '';

    return witness.join(' ');
  }

  /// Decodes a sequence of standard push-data opcodes (0x01–0x4b range).
  ///
  /// Returns [scriptHex] unchanged if any opcode is unrecognised or the
  /// script is truncated.
  String _decodePushData(String scriptHex) {
    final s = scriptHex.toLowerCase();
    if (s.isEmpty) return '';

    final items = <String>[];
    var pos = 0;

    while (pos + 2 <= s.length) {
      final opByte = int.tryParse(s.substring(pos, pos + 2), radix: 16);
      if (opByte == null) return scriptHex;

      if (opByte == 0x00) {
        items.add('OP_0');
        pos += 2;
      } else if (opByte >= 0x01 && opByte <= 0x4b) {
        // Direct push: next opByte bytes
        final dataStart = pos + 2;
        final dataEnd = dataStart + opByte * 2;
        if (dataEnd > s.length) return scriptHex; // truncated

        items.add(s.substring(dataStart, dataEnd));
        pos = dataEnd;
      } else {
        // Unrecognised opcode — return raw hex
        return scriptHex;
      }
    }

    if (items.isEmpty) return scriptHex;

    return items.join(' ');
  }
}
