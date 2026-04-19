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
  final converted = _convertBits(witnessProgram, 8, 5, pad: true)!;
  final data = [witnessVersion, ...converted];
  final spec = witnessVersion == 0 ? _bech32Constant : _bech32mConstant;
  final checksum = _createChecksum(hrp, data, spec);

  return '${hrp}1${[...data, ...checksum].map((d) => _charset[d]).join()}';
}

/// Decodes a SegWit address and returns the raw witness program bytes.
///
/// [hrp] — expected human-readable part (e.g. `bcrt` for regtest).
/// Returns null if the address is invalid or the HRP does not match.
Uint8List? segwitDecode(String address, String hrp) {
  final lower = address.toLowerCase();
  final sep = lower.lastIndexOf('1');
  if (sep < 1 || sep + 7 > lower.length) return null;

  final addrHrp = lower.substring(0, sep);
  if (addrHrp != hrp.toLowerCase()) return null;

  final data = <int>[];
  for (var i = sep + 1; i < lower.length; i++) {
    final idx = _charset.indexOf(lower[i]);
    if (idx == -1) return null;
    data.add(idx);
  }

  if (data.length < 8) return null;

  final witnessVersion = data[0];
  final spec = witnessVersion == 0 ? _bech32Constant : _bech32mConstant;

  if (!_verifyChecksum(addrHrp, data, spec)) return null;

  // Drop witness version byte and 6-byte checksum, then convert 5→8 bits
  final converted = _convertBits(
    data.sublist(1, data.length - 6),
    5,
    8,
  );
  if (converted == null || converted.length < 2 || converted.length > 40) {
    return null;
  }

  return Uint8List.fromList(converted);
}

// ---------------------------------------------------------------------------
// Internals
// ---------------------------------------------------------------------------

bool _verifyChecksum(String hrp, List<int> data, int spec) =>
    _polymod([..._hrpExpand(hrp), ...data]) == spec;

int _polymod(List<int> values) {
  const gen = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];
  var chk = 1;
  for (final v in values) {
    final top = chk >> 25;
    chk = ((chk & 0x1ffffff) << 5) ^ v;
    for (var i = 0; i < 5; i++) {
      if ((top >> i) & 1 == 1) chk ^= gen[i];
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

/// Converts between bit-widths.
///
/// Returns null when [pad] is false and remaining bits do not fit cleanly
/// (invalid padding in decode path).
List<int>? _convertBits(
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

  if (pad) {
    if (bits > 0) result.add((acc << (toBits - bits)) & maxv);
  } else if (bits >= fromBits || ((acc << (toBits - bits)) & maxv) != 0) {
    return null;
  }

  return result;
}
