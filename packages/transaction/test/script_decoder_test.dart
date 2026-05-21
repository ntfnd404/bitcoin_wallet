import 'package:test/test.dart';
import 'package:transaction/transaction.dart';

// ---------------------------------------------------------------------------
// Canonical hex fixtures
// ---------------------------------------------------------------------------

const _hash160 = '89abcdefabbaabbaabbaabbaabbaabbaabbaabba';
const _hash256 = '89abcdefabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabba';

const _p2pkh  = '76a914${_hash160}88ac';
const _p2sh   = 'a914${_hash160}87';
const _p2wpkh = '0014$_hash160';
const _p2wsh  = '0020$_hash256';
const _p2tr   = '5120$_hash256';

// OP_RETURN: 6a 05 68656c6c6f  →  OP_RETURN + push 5 + "hello"
const _opReturnWithData = '6a0568656c6c6f';
const _opReturnBare     = '6a';

// Standard P2PKH scriptSig: 47 <71-byte sig> 21 <33-byte pubkey>
final _sig           = 'ab' * 71;   // 142 hex chars (71 bytes)
final _pubkey        = 'cd' * 33;   // 66 hex chars (33 bytes)
final _p2pkhScriptSig = '47${'ab' * 71}21${'cd' * 33}';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const decoder = DefaultScriptDecoder();

  group('DefaultScriptDecoder — decode()', () {
    // SD1
    test('SD1: P2PKH → correct asm', () {
      expect(
        decoder.decode(_p2pkh),
        equals('OP_DUP OP_HASH160 $_hash160 OP_EQUALVERIFY OP_CHECKSIG'),
      );
    });

    // SD2
    test('SD2: P2SH → correct asm', () {
      expect(
        decoder.decode(_p2sh),
        equals('OP_HASH160 $_hash160 OP_EQUAL'),
      );
    });

    // SD3
    test('SD3: P2WPKH → correct asm', () {
      expect(decoder.decode(_p2wpkh), equals('OP_0 $_hash160'));
    });

    // SD4
    test('SD4: P2WSH → correct asm', () {
      expect(decoder.decode(_p2wsh), equals('OP_0 $_hash256'));
    });

    // SD5
    test('SD5: P2TR → correct asm', () {
      expect(decoder.decode(_p2tr), equals('OP_1 $_hash256'));
    });

    // SD6
    test('SD6: OP_RETURN with data → OP_RETURN <data>', () {
      // data after length byte: 68656c6c6f = "hello"
      expect(decoder.decode(_opReturnWithData), equals('OP_RETURN 68656c6c6f'));
    });

    // SD7
    test('SD7: bare OP_RETURN → "OP_RETURN"', () {
      expect(decoder.decode(_opReturnBare), equals('OP_RETURN'));
    });

    // SD8
    test('SD8: standard P2PKH scriptSig → two push items space-separated', () {
      final result = decoder.decode(_p2pkhScriptSig);
      expect(result, equals('${_sig.toLowerCase()} ${_pubkey.toLowerCase()}'));
    });

    // SD9
    test('SD9: empty string → empty string (no throw)', () {
      expect(decoder.decode(''), equals(''));
    });

    // SD10
    test('SD10: unknown/garbage hex → returned unchanged (no throw)', () {
      const garbage = 'deadbeef1234';
      expect(decoder.decode(garbage), equals(garbage));
    });

    // SD11
    test('SD11: malformed scriptSig (truncated push) → raw hex returned (no throw)', () {
      // Push opcode says 10 bytes but only 4 bytes follow
      const malformed = '0a11223344';
      expect(decoder.decode(malformed), equals(malformed));
    });
  });

  group('DefaultScriptDecoder — decodeWitness()', () {
    // SD12
    test('SD12: two-item witness stack → items joined with space', () {
      const sig    = '304402abcd01';
      const pubkey = '02aabbccdd';
      expect(
        decoder.decodeWitness([sig, pubkey]),
        equals('$sig $pubkey'),
      );
    });

    // SD13
    test('SD13: single-item witness stack → item returned as-is', () {
      expect(decoder.decodeWitness(['aabbcc']), equals('aabbcc'));
    });

    // SD14
    test('SD14: multi-item witness stack (>2) → all items joined', () {
      expect(
        decoder.decodeWitness(['aa', 'bb', 'cc']),
        equals('aa bb cc'),
      );
    });

    // SD15
    test('SD15: empty witness list → empty string (no throw)', () {
      expect(decoder.decodeWitness([]), equals(''));
    });
  });
}
