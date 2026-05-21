import 'dart:typed_data';

import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/exception/insufficient_funds_exception.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/broadcast_gateway.dart';
import 'package:transaction/src/domain/gateway/node_transaction_gateway.dart';
import 'package:transaction/src/domain/repository/utxo_repository.dart';
import 'package:transaction/src/domain/service/eligibility_policy.dart';
import 'package:transaction/src/domain/service/fee_estimator.dart';
import 'package:transaction/src/domain/service/op_return_script_builder.dart';
import 'package:transaction/src/domain/service/utxo_eligibility_filter.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/tx_output.dart';

/// Constructs, signs, and broadcasts an OP_RETURN transaction for the Node wallet.
///
/// Selects UTXOs greedily (largest-first) to cover the transaction fee,
/// constructs a raw transaction with one OP_RETURN output (0 sat) and an
/// optional change output, signs it via Bitcoin Core, and broadcasts it.
///
/// [data] must be 1–80 bytes (enforced by [buildOpReturnScript]).
///
/// Throws:
/// - [InsufficientFundsException] when no combination of UTXOs covers the fee.
/// - [TransactionSigningException] when Core wallet signing fails.
/// - [TransactionBroadcastException] when `sendrawtransaction` is rejected.
/// - [TransactionPreparationException] for UTXO fetch or RPC failures.
final class SendOpReturnUseCase {
  final UtxoRepository _utxoRepository;
  final NodeTransactionGateway _nodeDataSource;
  final BroadcastGateway _broadcastDataSource;
  final FeeEstimator _feeEstimator;
  final UtxoEligibilityFilter _eligibilityFilter;

  const SendOpReturnUseCase({
    required this._utxoRepository,
    required this._nodeDataSource,
    required this._broadcastDataSource,
    required this._feeEstimator,
    this._eligibilityFilter = const DefaultUtxoEligibilityFilter(),
  });

  Future<String> call({
    required String walletName,
    required Uint8List data,
    required int feeRateSatPerVbyte,
  }) async {
    try {
      // 1. Fetch, filter, and apply eligibility policy.
      final allUtxos = await _utxoRepository.getUtxos(walletName);
      final candidates = allUtxos
          .where((u) => u.spendable)
          .map((u) => CoinCandidate(
            txid: u.txid,
            vout: u.vout,
            amountSat: u.amountSat,
            age: u.confirmations,
            scriptType: u.type,
            confirmations: u.confirmations,
          ))
          .toList();

      final eligible = _eligibilityFilter.filter(
        candidates,
        EligibilityPolicy.node,
        _feeEstimator,
        feeRateSatPerVbyte,
      );

      // 2. Greedy largest-first selection.
      final sorted = List.of(eligible)
        ..sort((a, b) => b.amountSat.value.compareTo(a.amountSat.value));

      final selected = <CoinCandidate>[];
      var totalInput = 0;

      for (final candidate in sorted) {
        selected.add(candidate);
        totalInput += candidate.amountSat.value;

        final feeWith2 = _feeEstimator.estimateForCandidates(
          inputs: selected,
          outputs: 2,
          feeRateSatPerVbyte: feeRateSatPerVbyte,
        );
        if (totalInput >= feeWith2.value) break;
      }

      // 3. Check sufficiency for at least one output (OP_RETURN only, no change).
      final feeWith1 = _feeEstimator.estimateForCandidates(
        inputs: selected,
        outputs: 1,
        feeRateSatPerVbyte: feeRateSatPerVbyte,
      );
      if (totalInput < feeWith1.value) {
        throw InsufficientFundsException(
          available: Satoshi(totalInput),
          required: feeWith1,
        );
      }

      // 4. Determine change (absorb dust into fee).
      final feeWith2 = _feeEstimator.estimateForCandidates(
        inputs: selected,
        outputs: 2,
        feeRateSatPerVbyte: feeRateSatPerVbyte,
      );
      final dustThreshold = _feeEstimator.dustThreshold(AddressType.nativeSegwit);
      final changeSat = totalInput - feeWith2.value;
      final hasChange = changeSat >= dustThreshold;

      // 5. Build raw data hex — Bitcoin Core prepends OP_RETURN opcode + push encoding.
      final dataHex = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      // 6. Assemble typed outputs.
      final rpcInputs = selected.map((c) => (txid: c.txid, vout: c.vout)).toList();
      final rpcOutputs = <TxOutput>[OpReturnOutput(dataHex)];

      if (hasChange) {
        final changeAddress = await _nodeDataSource.getNewAddress(walletName);
        rpcOutputs.add(AddressOutput(
          address: changeAddress,
          amountBtc: Satoshi(changeSat).btcAmount,
        ));
      }

      // 7. Construct → sign → broadcast.
      final hexUnsigned = await _nodeDataSource.createRawTransaction(
        inputs: rpcInputs,
        outputs: rpcOutputs,
      );
      final hexSigned = await _nodeDataSource.signRawTransactionWithWallet(
        walletName,
        hexUnsigned,
      );

      return await _broadcastDataSource.broadcast(hexSigned);
    } on InsufficientFundsException {
      rethrow;
    } on TransactionException {
      rethrow;
    } on Exception catch (_, stack) {
      Error.throwWithStackTrace(const TransactionPreparationException(), stack);
    }
    // Programmer errors propagate to the zone handler.
  }
}
