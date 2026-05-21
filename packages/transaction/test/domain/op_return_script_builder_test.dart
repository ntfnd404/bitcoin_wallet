import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:transaction/transaction.dart';

void main() {
  group('buildOpReturnScript', () {
    // ORS1: 1-byte payload → direct push
    test('ORS1: 1-byte payload uses direct push (6a 01 <byte>)', () {
      final data = Uint8List.fromList([0xab]);
      expect(buildOpReturnScript(data), equals('6a01ab'));
    });

    // ORS2: 75-byte payload → direct push (boundary)
    test('ORS2: 75-byte payload uses direct push (6a 4b <75 bytes>)', () {
      final data = Uint8List.fromList(List.filled(75, 0xcc));
      final result = buildOpReturnScript(data);
      // 6a + 4b (75 in hex) + cc * 75
      expect(result, equals('6a4b${'cc' * 75}'));
    });

    // ORS3: 76-byte payload → OP_PUSHDATA1
    test('ORS3: 76-byte payload uses OP_PUSHDATA1 (6a 4c 4c <76 bytes>)', () {
      final data = Uint8List.fromList(List.filled(76, 0xdd));
      final result = buildOpReturnScript(data);
      // 6a + 4c (OP_PUSHDATA1) + 4c (76 in hex) + dd * 76
      expect(result, equals('6a4c4c${'dd' * 76}'));
    });

    // ORS4: 80-byte payload → OP_PUSHDATA1 (maximum)
    test('ORS4: 80-byte payload uses OP_PUSHDATA1 (6a 4c 50 <80 bytes>)', () {
      final data = Uint8List.fromList(List.filled(80, 0xee));
      final result = buildOpReturnScript(data);
      // 6a + 4c (OP_PUSHDATA1) + 50 (80 in hex) + ee * 80
      expect(result, equals('6a4c50${'ee' * 80}'));
    });

    // ORS5: empty payload → ArgumentError
    test('ORS5: empty payload throws ArgumentError', () {
      expect(
        () => buildOpReturnScript(Uint8List(0)),
        throwsA(isA<ArgumentError>()),
      );
    });

    // ORS6: 81-byte payload → ArgumentError
    test('ORS6: 81-byte payload throws ArgumentError', () {
      expect(
        () => buildOpReturnScript(Uint8List.fromList(List.filled(81, 0xff))),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
