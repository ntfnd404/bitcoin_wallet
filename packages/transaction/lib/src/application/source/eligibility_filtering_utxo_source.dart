import 'package:transaction/src/domain/contract/utxo_source.dart';
import 'package:transaction/src/domain/service/eligibility_policy.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/service/utxo_eligibility_filter.dart';
import 'package:transaction/src/domain/value_object/utxo_source_result.dart';

/// Decorator that applies a [UtxoEligibilityFilter] to the candidates returned
/// by an inner [UtxoSource]. Pass-through for `changeAddress` and
/// `signingContext`.
///
/// No catch: any exception raised by the inner source propagates unchanged
/// (decorator transparency). The filter call itself is synchronous and only
/// throws programmer errors, which propagate to the zone handler.
final class EligibilityFilteringUtxoSource implements UtxoSource {
  final UtxoSource _inner;
  final EligibilityPolicy _policy;
  final UtxoEligibilityFilter _filter;
  final FeeEstimator _feeEstimator;
  final int _feeRateSatPerVbyte;

  const EligibilityFilteringUtxoSource({
    required this._inner,
    required this._policy,
    required this._filter,
    required this._feeEstimator,
    required this._feeRateSatPerVbyte,
  });

  @override
  Future<UtxoSourceResult> resolve() async {
    final inner = await _inner.resolve();
    final filtered = _filter.filter(
      inner.candidates,
      _policy,
      _feeEstimator,
      _feeRateSatPerVbyte,
    );

    return UtxoSourceResult(
      candidates: filtered,
      changeAddress: inner.changeAddress,
      signingContext: inner.signingContext,
    );
  }
}
