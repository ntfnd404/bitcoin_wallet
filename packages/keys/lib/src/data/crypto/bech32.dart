import 'dart:typed_data';

const _charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
const _bech32Constant = 1;
const _bech32mConstant = 0x2bc830a3;

/// Encodes a SegWit address using Bech32 (witness v0) or Bech32m (witness v1+).
///
/// [hrp] — human-readable part (e.g. `bcrt` for regtest).
/// [witnessVersion] — 0 for P2WPKH/P2WSH, 1 for P2TR.
/// [witnessProgram] — the witness program bytes (20 or 32 bytes).
String segwitEncode(String hrp, int witnessVersion, Uint8List witnessProgram) {
  final converted = _convertBits(witnessProgram, 8, 5, pad: true);
  final data = [witnessVersion, ...converted];
  final spec = witnessVersion == 0 ? _bech32Constant : _bech32mConstant;
  final checksum = _createChecksum(hrp, data, spec);

  return '${hrp}1${[...data, ...checksum].map((d) => _charset[d]).join()}';
}

// ---------------------------------------------------------------------------
// Bech32 internals
// ---------------------------------------------------------------------------

int _polymod(List<int> values) {
  const gen = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];
  var chk = 1;
  for (final v in values) {
    final top = chk >> 25;
    chk = ((chk & 0x1ffffff) << 5) ^ v;
    for (var i = 0; i < 5; i++) {
      if ((top >> i) & 1 == 1) {
        chk ^= gen[i];
      }
    }
  }

  return chk;
}

List<int> _hrpExpand(String hrp) {
  final result = <int>[];
  for (final c in hrp.codeUnits) {
    result.add(c >> 5);
  }
  result.add(0);
  for (final c in hrp.codeUnits) {
    result.add(c & 31);
  }

  return result;
}

List<int> _createChecksum(String hrp, List<int> data, int spec) {
  final values = [..._hrpExpand(hrp), ...data, 0, 0, 0, 0, 0, 0];
  final polymod = _polymod(values) ^ spec;

  return List.generate(6, (i) => (polymod >> (5 * (5 - i))) & 31);
}

List<int> _convertBits(
  List<int> data,
  int fromBits,
  int toBits, {
  bool pad = false,
}) {
  var acc = 0;
  var bits = 0;
  final result = <int>[];
  final maxv = (1 << toBits) - 1;

  for (final value in data) {
    acc = (acc << fromBits) | value;
    bits += fromBits;
    while (bits >= toBits) {
      bits -= toBits;
      result.add((acc >> bits) & maxv);
    }
  }

  if (pad && bits > 0) {
    result.add((acc << (toBits - bits)) & maxv);
  }

  return result;
}
