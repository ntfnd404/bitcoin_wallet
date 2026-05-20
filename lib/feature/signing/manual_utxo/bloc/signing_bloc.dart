import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/core/event_bus/events/transaction_event.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_action.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_event.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keys/keys.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

final class SigningBloc extends Bloc<SigningEvent, SigningState> with ActionBlocMixin<SigningState, SigningAction> {
  final AddressRepository _addressRepository;
  final ScanUtxosUseCase _scanUtxos;
  final SignTransactionUseCase _signTransaction;
  final BroadcastTransactionUseCase _broadcastTransaction;
  final AppEventBus _eventBus;

  SigningBloc({
    required AddressRepository addressRepository,
    required ScanUtxosUseCase scanUtxos,
    required SignTransactionUseCase signTransaction,
    required BroadcastTransactionUseCase broadcastTransaction,
    required AppEventBus eventBus,
  }) : _addressRepository = addressRepository,
       _scanUtxos = scanUtxos,
       _signTransaction = signTransaction,
       _broadcastTransaction = broadcastTransaction,
       _eventBus = eventBus,
       super(const SigningState()) {
    on<UtxoScanRequested>(_onScanRequested);
    on<SignAndBroadcastRequested>(_onSignAndBroadcast);
  }

  Future<void> _onScanRequested(
    UtxoScanRequested event,
    Emitter<SigningState> emit,
  ) async {
    emit(const SigningState(status: SigningStatus.scanning));
    try {
      final addresses = await _addressRepository.getAddresses(event.walletId);
      if (isClosed) return;
      final segwit = addresses.where((a) => a.type == AddressType.nativeSegwit).toList();

      if (segwit.isEmpty) {
        emitAction(SigningNoAddressesFoundAction());
        emit(const SigningState());

        return;
      }

      final indexMap = {for (final a in segwit) a.value: a.index};
      final utxos = await _scanUtxos(segwit.map((a) => a.value).toList());
      if (isClosed) return;

      emit(SigningState(status: SigningStatus.scanned, utxos: utxos, addressIndexMap: indexMap));
    } on TransactionException catch (e) {
      if (isClosed) return;
      emitAction(SigningTransactionFailedAction(exception: e));
      emit(const SigningState());
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emit(const SigningState());
    }
  }

  Future<void> _onSignAndBroadcast(
    SignAndBroadcastRequested event,
    Emitter<SigningState> emit,
  ) async {
    final utxos = state.utxos;
    if (utxos.isEmpty) {
      emitAction(SigningNoUtxosFoundAction());
      emit(state.copyWith(status: SigningStatus.idle));

      return;
    }

    emit(state.copyWith(status: SigningStatus.signing));
    try {
      final inputs = utxos.map((utxo) {
        final address = utxo.address;
        final index = address != null ? state.addressIndexMap[address] : null;
        if (index == null) {
          throw const TransactionSigningException();
        }

        return SigningInputParam(
          txid: utxo.txid,
          vout: utxo.vout,
          amountSat: utxo.amountSat,
          type: AddressType.nativeSegwit,
          derivationIndex: index,
        );
      }).toList();

      final outputs = [
        SigningOutput(
          address: event.recipientAddress,
          amountSat: Satoshi(event.amountSat),
        ),
      ];

      final rawHex = await _signTransaction(
        walletId: event.walletId,
        inputs: inputs,
        outputs: outputs,
        bech32Hrp: event.bech32Hrp,
      );
      if (isClosed) return;

      final txid = await _broadcastTransaction.broadcast(rawHex);
      if (isClosed) return;

      final broadcastedTx = await _broadcastTransaction.getTransaction(txid);
      if (isClosed) return;

      emit(
        state.copyWith(
          status: SigningStatus.broadcasted,
          txid: txid,
          broadcastedTx: broadcastedTx,
        ),
      );
      _eventBus.emit(TransactionBroadcasted(txid: txid, walletId: event.walletId));
    } on KeysException catch (e) {
      if (isClosed) return;
      emitAction(SigningKeysFailedAction(exception: e));
      emit(state.copyWith(status: SigningStatus.idle));
    } on TransactionException catch (e) {
      if (isClosed) return;
      emitAction(SigningTransactionFailedAction(exception: e));
      emit(state.copyWith(status: SigningStatus.idle));
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: SigningStatus.idle));
    }
  }
}
