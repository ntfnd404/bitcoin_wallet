import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/application/node_send_preparation.dart';
import 'package:transaction/src/domain/data_sources/node_transaction_data_source.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/repository/utxo_repository.dart';
import 'package:transaction/src/domain/service/coin_selector.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/coin_selection_result.dart';

/// Fetches Node-wallet UTXOs, runs all coin-selection strategies, and returns
/// a [NodeSendPreparation] for the UI comparison table.
///
/// Does not broadcast — call [SendNodeTransactionUseCase] after confirmation.
final class PrepareNodeSendUseCase {
  final UtxoRepository _utxoRepository;
  final NodeTransactionDataSource _nodeDataSource;
  final List<CoinSelector> _selectors;
  final FeeEstimator _feeEstimator;

  const PrepareNodeSendUseCase({
    required UtxoRepository utxoRepository,
    required NodeTransactionDataSource nodeDataSource,
    required List<CoinSelector> selectors,
    required FeeEstimator feeEstimator,
  })  : _utxoRepository = utxoRepository,
        _nodeDataSource = nodeDataSource,
        _selectors = selectors,
        _feeEstimator = feeEstimator;

  Future<NodeSendPreparation> call({
    required String walletName,
    required Satoshi targetSat,
    required int feeRateSatPerVbyte,
  }) async {
    final utxos = await _utxoRepository.getUtxos(walletName);

    final candidates = utxos
        .map(
          (u) => CoinCandidate(
            txid: u.txid,
            vout: u.vout,
            amountSat: u.amountSat,
            age: u.confirmations,
          ),
        )
        .toList();

    final changeAddress = await _nodeDataSource.getNewAddress(walletName);

    final strategies = <String, CoinSelectionResult>{};
    for (final selector in _selectors) {
      try {
        strategies[selector.name] = selector.select(
          candidates: candidates,
          targetSat: targetSat,
          feeEstimator: _feeEstimator,
          feeRateSatPerVbyte: feeRateSatPerVbyte,
          dustThreshold: 546,
        );
      } on InsufficientFundsException {
        // Strategy could not cover the amount — omit from comparison table.
      }
    }

    return NodeSendPreparation(
      candidates: candidates,
      strategies: Map.unmodifiable(strategies),
      changeAddress: changeAddress,
    );
  }
}
