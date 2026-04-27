import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/core/event_bus/events/transaction_event.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_event.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_state.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// Orchestrates the two-step send flow: prepare (coin selection) → confirm (broadcast).
///
/// Exactly one of [_prepareNode]/[_sendNode] or [_prepareHd]/[_sendHd] is non-null,
/// determined at construction time by [wallet] type.
final class SendBloc extends Bloc<SendEvent, SendState> {
  final Wallet _wallet;

  // Node wallet path (non-null when wallet.isNode)
  final PrepareNodeSendUseCase? _prepareNode;
  final SendNodeTransactionUseCase? _sendNode;

  // HD wallet path (non-null when wallet.isHd)
  final PrepareHdSendUseCase? _prepareHd;
  final SendHdTransactionUseCase? _sendHd;

  // Shared
  final BlockGenerationDataSource _blockGeneration;
  final String _bech32Hrp;
  final AppEventBus _eventBus;

  // Internal — holds the preparation DTO between prepare and confirm steps.
  NodeSendPreparation? _nodePrep;
  HdSendPreparation? _hdPrep;

  SendBloc({
    required Wallet wallet,
    PrepareNodeSendUseCase? prepareNode,
    SendNodeTransactionUseCase? sendNode,
    PrepareHdSendUseCase? prepareHd,
    SendHdTransactionUseCase? sendHd,
    required BlockGenerationDataSource blockGeneration,
    required String bech32Hrp,
    required AppEventBus eventBus,
  }) : _wallet = wallet,
       _prepareNode = prepareNode,
       _sendNode = sendNode,
       _prepareHd = prepareHd,
       _sendHd = sendHd,
       _blockGeneration = blockGeneration,
       _bech32Hrp = bech32Hrp,
       _eventBus = eventBus,
       super(const SendState()) {
    on<SendFormSubmitted>(_onFormSubmitted);
    on<SendStrategySelected>(_onStrategySelected);
    on<SendConfirmed>(_onConfirmed);
    on<MineBlockRequested>(_onMineBlock);
  }

  Future<void> _onFormSubmitted(
    SendFormSubmitted event,
    Emitter<SendState> emit,
  ) async {
    emit(state.copyWith(status: SendStatus.preparing));

    try {
      final targetSat = Satoshi(event.amountSat);
      final Map<String, CoinSelectionResult> strategies;
      final String changeAddress;

      if (_prepareNode != null) {
        _nodePrep = await _prepareNode.call(
          walletName: _wallet.name,
          targetSat: targetSat,
          feeRateSatPerVbyte: event.feeRateSatPerVbyte,
        );
        strategies = _nodePrep!.strategies;
        changeAddress = _nodePrep!.changeAddress;
      } else {
        _hdPrep = await _prepareHd!.call(
          walletId: _wallet.id,
          targetSat: targetSat,
          feeRateSatPerVbyte: event.feeRateSatPerVbyte,
        );
        strategies = _hdPrep!.strategies;
        changeAddress = _hdPrep!.changeAddress;
      }

      if (strategies.isEmpty) {
        emit(
          state.copyWith(
            status: SendStatus.error,
            errorMessage: 'Insufficient funds for any strategy',
          ),
        );

        return;
      }

      emit(
        state.copyWith(
          status: SendStatus.awaitingConfirmation,
          strategies: strategies,
          selectedStrategy: strategies.keys.first,
          changeAddress: changeAddress,
          recipientAddress: event.recipientAddress,
          amountSat: event.amountSat,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SendStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onStrategySelected(
    SendStrategySelected event,
    Emitter<SendState> emit,
  ) {
    emit(state.copyWith(selectedStrategy: event.strategyName));
  }

  Future<void> _onConfirmed(
    SendConfirmed event,
    Emitter<SendState> emit,
  ) async {
    final strategyName = state.selectedStrategy;
    final recipientAddress = state.recipientAddress;
    final amountSat = state.amountSat;

    if (strategyName == null || recipientAddress == null || amountSat == null) {
      return;
    }

    emit(state.copyWith(status: SendStatus.sending));

    try {
      final String txid;

      if (_sendNode != null && _nodePrep != null) {
        txid = await _sendNode.call(
          preparation: _nodePrep!,
          strategyName: strategyName,
          walletName: _wallet.name,
          recipientAddress: recipientAddress,
          amountSat: Satoshi(amountSat),
        );
      } else {
        txid = await _sendHd!.call(
          preparation: _hdPrep!,
          strategyName: strategyName,
          walletId: _wallet.id,
          recipientAddress: recipientAddress,
          amountSat: Satoshi(amountSat),
          bech32Hrp: _bech32Hrp,
        );
      }

      emit(state.copyWith(status: SendStatus.sent, txid: txid));
      _eventBus.emit(TransactionBroadcasted(txid: txid, walletId: _wallet.id));
    } catch (e) {
      emit(
        state.copyWith(
          status: SendStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onMineBlock(
    MineBlockRequested event,
    Emitter<SendState> emit,
  ) async {
    emit(state.copyWith(status: SendStatus.mining));

    try {
      await _blockGeneration.generateToAddress(1, event.toAddress);
      emit(state.copyWith(status: SendStatus.mined));
      _eventBus.emit(BlockMined(walletId: _wallet.id));
    } catch (e) {
      emit(
        state.copyWith(
          status: SendStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
