import 'package:test/test.dart';
import 'package:transaction/transaction.dart';

// ---------------------------------------------------------------------------
// Canonical hex fixtures
// ---------------------------------------------------------------------------

// 20-byte hash160 (40 hex chars)
const _hash160 = '89abcdefabbaabbaabbaabbaabbaabbaabbaabba';
// 32-byte hash/pubkey (64 hex chars)
const _hash256 = '89abcdefabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabba';

const _p2pkh   = '76a914${_hash160}88ac';          // 50 hex
const _p2sh    = 'a914${_hash160}87';               // 46 hex
const _p2wpkh  = '0014$_hash160';                   // 44 hex
const _p2wsh   = '0020$_hash256';                   // 68 hex
const _p2tr    = '5120$_hash256';                   // 68 hex
const _opReturnWithData = '6a0568656c6c6f';         // OP_RETURN "hello"
const _opReturnBare     = '6a';

// P2PKH with wrong total length — 38 hex chars for hash instead of 40 → total 48 hex ≠ 50
// '76a914' + 38 chars + '88ac' = 48 hex chars
const _p2pkhWrongLength = '76a91489abcdefabbaabbaabbaabbaabbaabbaab88ac';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const classifier = DefaultScriptClassifier();

  group('DefaultScriptClassifier', () {
    // SC1
    test('SC1: P2PKH script returns ScriptType.p2pkh', () {
      expect(classifier.classify(_p2pkh), equals(ScriptType.p2pkh));
    });

    // SC2
    test('SC2: P2SH script returns ScriptType.p2sh', () {
      expect(classifier.classify(_p2sh), equals(ScriptType.p2sh));
    });

    // SC3
    test('SC3: P2WPKH script returns ScriptType.p2wpkh', () {
      expect(classifier.classify(_p2wpkh), equals(ScriptType.p2wpkh));
    });

    // SC4
    test('SC4: P2WSH script returns ScriptType.p2wsh', () {
      expect(classifier.classify(_p2wsh), equals(ScriptType.p2wsh));
    });

    // SC5
    test('SC5: P2TR script returns ScriptType.p2tr', () {
      expect(classifier.classify(_p2tr), equals(ScriptType.p2tr));
    });

    // SC6
    test('SC6: OP_RETURN with data returns ScriptType.opReturn', () {
      expect(classifier.classify(_opReturnWithData), equals(ScriptType.opReturn));
    });

    // SC7
    test('SC7: bare OP_RETURN (6a only) returns ScriptType.opReturn', () {
      expect(classifier.classify(_opReturnBare), equals(ScriptType.opReturn));
    });

    // SC8
    test('SC8: P2PKH prefix with wrong total length returns ScriptType.unknown', () {
      expect(classifier.classify(_p2pkhWrongLength), equals(ScriptType.unknown));
    });

    // SC9
    test('SC9: empty string returns ScriptType.unknown', () {
      expect(classifier.classify(''), equals(ScriptType.unknown));
    });

    // SC10
    test('SC10: arbitrary non-matching hex returns ScriptType.unknown', () {
      expect(classifier.classify('deadbeef1234'), equals(ScriptType.unknown));
    });

    // SC11
    test('SC11: ScriptType labels are correct', () {
      expect(ScriptType.p2pkh.label,    equals('P2PKH'));
      expect(ScriptType.p2sh.label,     equals('P2SH'));
      expect(ScriptType.p2wpkh.label,   equals('P2WPKH'));
      expect(ScriptType.p2wsh.label,    equals('P2WSH'));
      expect(ScriptType.p2tr.label,     equals('P2TR'));
      expect(ScriptType.opReturn.label, equals('OP_RETURN'));
      expect(ScriptType.unknown.label,  equals('UNKNOWN'));
    });
  });
}
