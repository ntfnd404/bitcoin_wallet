import 'dart:convert';
import 'dart:typed_data';

import 'package:keys/src/domain/entity/signing_input.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';

void main() {
  group('keys.SigningInput', () {
    test('toString does not expose privateKey or publicKey bytes', () {
      // Sentinel bytes: 0xAB for private key, 0xCD for public key.
      // Two distinct sentinels let the assertion distinguish which field leaked.
      final privateKey = Uint8List.fromList(List.filled(32, 0xAB));
      final publicKey = Uint8List.fromList(List.filled(33, 0xCD));

      final input = SigningInput(
        txid: 'deadbeef',
        vout: 0,
        amountSat: const Satoshi(100000),
        privateKey: privateKey,
        publicKey: publicKey,
      );

      final output = input.toString();

      // Must not contain hex representation of sentinel bytes.
      expect(output, isNot(contains('ab')));
      expect(output, isNot(contains('AB')));
      expect(output, isNot(contains('cd')));
      expect(output, isNot(contains('CD')));

      // Must not contain base64 of the sentinel private key
      // (base64.encode of List.filled(32, 0xAB) = 'q6urq6urq6urq6urq6urq6urq6urq6ur').
      expect(
        output,
        isNot(contains(base64.encode(privateKey))),
      );

      // Must not contain base64 of the sentinel public key.
      expect(
        output,
        isNot(contains(base64.encode(publicKey))),
      );

      // Safe fields ARE present.
      expect(output, contains('deadbeef'));
      expect(output, contains('100000'));
    });
  });
}
