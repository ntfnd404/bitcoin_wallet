import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/node/node_send_preparation.dart';
import 'package:transaction/src/domain/entity/utxo.dart';
import 'package:transaction/src/domain/exception/coin_selection_no_solution_exception.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/node_transaction_gateway.dart';
import 'package:transaction/src/domain/service/coin_selection_request.dart';
import 'package:transaction/src/domain/service/coin_selector.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_strategy_result.dart';

/// Node send preparation that uses a caller-supplied list of UTXOs as fixed
/// inputs instead of fetching from the repository.
///
/// Skips the UTXO repository fetch and the eligibility filter — the caller is
/// responsible for passing only UTXOs it wants to pin as inputs.
/// All coin-selection strategies are run against the pinned candidates and
/// the result is returned as a [NodeSendPreparation].
final class PrepareNodePinnedSendUseCase {
  final NodeTransactionGateway _nodeDataSource;
  final List<CoinSelector> _selectors;
  final FeeEstimator _feeEstimator;

  const PrepareNodePinnedSendUseCase({
    required this._nodeDataSource,
    required this._selectors,
    required this._feeEstimator,
  });

  Future<NodeSendPreparation> call({
    required String walletName,
    required List<Utxo> pinnedInputs,
    required Satoshi targetSat,
    required int feeRateSatPerVbyte,
  }) async {
    try {
      final candidates = pinnedInputs.map(_toCandidate).toList();
      final changeAddress = await _nodeDataSource.getNewAddress(walletName);

      final strategies = <CoinSelectionStrategyResult>[];
      for (final selector in _selectors) {
        try {
          strategies.add(
            CoinSelectionStrategyResult(
              name: selector.name,
              isStochastic: selector.isStochastic,
              result: selector.select(
                CoinSelectionRequest(
                  candidates: candidates,
                  targetSat: targetSat,
                  feeEstimator: _feeEstimator,
                  feeRateSatPerVbyte: feeRateSatPerVbyte,
                  dustThreshold: _feeEstimator.dustThreshold(AddressType.nativeSegwit),
                ),
              ),
            ),
          );
        } on InsufficientFundsException {
          // Strategy could not cover the amount — omit.
        } on CoinSelectionNoSolutionException {
          // Strategy has no exact solution — omit from comparison table.
        }
      }

      return NodeSendPreparation(
        candidates: candidates,
        strategies: List.unmodifiable(strategies),
        changeAddress: changeAddress,
      );
    } on InsufficientFundsException {
      rethrow;
    } on TransactionException {
      rethrow;
    } on Exception catch (_, stack) {
      Error.throwWithStackTrace(const TransactionPreparationException(), stack);
    }
  }

  CoinCandidate _toCandidate(Utxo u) => CoinCandidate(
    txid: u.txid,
    vout: u.vout,
    amountSat: u.amountSat,
    age: u.confirmations,
    scriptType: u.type,
    scriptPubKeyHex: u.scriptPubKey,
    confirmations: u.confirmations,
  );
}
