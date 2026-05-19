import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/transaction.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
//
// fee(1, 2) at feeRate=1 for P2WPKH = (10 + 68 + 62) = 140 sat
// effectiveSatoshis(c) = c.amountSat - inputVbytes * feeRate = c.amountSat - 68

const _estimator = P2wpkhFeeEstimator();
const _feeRate = 1;
const _filter = DefaultUtxoEligibilityFilter();

CoinCandidate _c({
  required int sat,
  int? confirmations,
  String txid = 'tx',
  int vout = 0,
}) =>
    CoinCandidate(
      txid: txid,
      vout: vout,
      amountSat: Satoshi(sat),
      age: confirmations ?? 1,
      confirmations: confirmations,
    );

// ---------------------------------------------------------------------------

void main() {
  group('DefaultUtxoEligibilityFilter', () {
    // EF1 — node policy requires minConfirmations=1; 0-confirmed excluded.
    test('EF1: excludes candidate with 0 confirmations under node policy', () {
      final c = _c(sat: 10000, confirmations: 0);
      final result = _filter.filter([c], EligibilityPolicy.node, _estimator, _feeRate);

      expect(result, isEmpty);
    });

    // EF2 — node policy: allowUnknownConfirmations=false; null excluded.
    test('EF2: excludes candidate with null confirmations under node policy', () {
      final c = _c(sat: 10000);
      final result = _filter.filter([c], EligibilityPolicy.node, _estimator, _feeRate);

      expect(result, isEmpty);
    });

    // EF3 — HD policy: allowUnknownConfirmations=true; null passes through.
    test('EF3: allows candidate with null confirmations under HD policy', () {
      final c = _c(sat: 10000);
      final result = _filter.filter([c], EligibilityPolicy.hd, _estimator, _feeRate);

      expect(result, hasLength(1));
    });

    // EF4 — dust: effectiveSatoshis = 68 - 68 = 0 → excluded (allowDust=false).
    test('EF4: excludes dust candidate (effectiveSatoshis <= 0) when allowDust is false', () {
      // amountSat == inputVbytes * feeRate → effectiveSatoshis == 0
      final dust = _c(sat: 68, confirmations: 1);
      final result = _filter.filter([dust], EligibilityPolicy.node, _estimator, _feeRate);

      expect(result, isEmpty);
    });

    // EF5 — eligible: 1 confirmation, positive effective value → passes.
    test('EF5: passes eligible candidate (confirmed, positive effective value)', () {
      final c = _c(sat: 10000, confirmations: 1);
      final result = _filter.filter([c], EligibilityPolicy.node, _estimator, _feeRate);

      expect(result, hasLength(1));
      expect(result.first.txid, equals('tx'));
    });

    // Mixed: only eligible candidates survive.
    test('returns only eligible candidates from a mixed list', () {
      final eligible = _c(sat: 10000, confirmations: 2, txid: 'good');
      final unconfirmed = _c(sat: 10000, confirmations: 0, txid: 'unconf');
      final dust = _c(sat: 68, confirmations: 1, txid: 'dust');

      final result = _filter.filter(
        [eligible, unconfirmed, dust],
        EligibilityPolicy.node,
        _estimator,
        _feeRate,
      );

      expect(result, hasLength(1));
      expect(result.first.txid, equals('good'));
    });
  });
}
