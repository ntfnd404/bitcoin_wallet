/// The recognised Bitcoin scriptPubKey types.
enum ScriptType {
  p2pkh,
  p2sh,
  p2wpkh,
  p2wsh,
  p2tr,
  opReturn,
  unknown;

  /// Short human-readable label for UI display.
  String get label => switch (this) {
    ScriptType.p2pkh => 'P2PKH',
    ScriptType.p2sh => 'P2SH',
    ScriptType.p2wpkh => 'P2WPKH',
    ScriptType.p2wsh => 'P2WSH',
    ScriptType.p2tr => 'P2TR',
    ScriptType.opReturn => 'OP_RETURN',
    ScriptType.unknown => 'UNKNOWN',
  };
}
