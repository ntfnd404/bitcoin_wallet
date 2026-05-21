import 'dart:typed_data';

/// Builds OP_RETURN scriptPubKey hex for [data].
///
/// Encoding:
///   1–75 bytes  → `6a <len_1byte> <data>`       (direct push)
///   76–80 bytes → `6a 4c <len_1byte> <data>`    (OP_PUSHDATA1)
///
/// Throws [ArgumentError] if [data] is empty or exceeds 80 bytes.
String buildOpReturnScript(Uint8List data) {
  if (data.isEmpty) {
    throw ArgumentError.value(data, 'data', 'OP_RETURN data must not be empty');
  }
  if (data.length > 80) {
    throw ArgumentError.value(
      data,
      'data',
      'OP_RETURN data exceeds 80-byte limit (got ${data.length})',
    );
  }

  final buf = StringBuffer('6a');

  if (data.length <= 75) {
    buf.write(data.length.toRadixString(16).padLeft(2, '0'));
  } else {
    // OP_PUSHDATA1 prefix
    buf.write('4c');
    buf.write(data.length.toRadixString(16).padLeft(2, '0'));
  }

  for (final byte in data) {
    buf.write(byte.toRadixString(16).padLeft(2, '0'));
  }

  return buf.toString();
}
