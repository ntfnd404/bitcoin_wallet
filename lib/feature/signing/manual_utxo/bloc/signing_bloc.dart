import 'package:address/address.dart';
import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/core/event_bus/events/transaction_event.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_event.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keys/keys.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

/// BLoC that orchestrates the HD wallet sign-and-broadcast demo flow.
///
/// Step 1 — [UtxoScanRequested]: derives stored native SegWit addresses,
///           scans the UTXO set via `scantxoutset`.
/// Step 2 — [SignAndBroadcastRequested]: signs all found UTXOs as inputs,
///           broadcasts the transaction, and verifies via `getrawtransaction`.
final class SigningBloc extends Bloc<SigningEvent, SigningState> {
  final AddressRepository _addressRepository;
  final ScanUtxosUseCase _scanUtxos;
  final SignTransactionUseCase _signTransaction;
  final BroadcastTransactionUseCase _broadcastTransaction;
  final AppEventBus _eventBus;

  /// Maps native SegWit address string → derivation index.
  /// Populated during [UtxoScanRequested], consumed during [SignAndBroadcastRequested].
  final Map<String, int> _addressIndexMap = {};

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
      final segwit = addresses.where((a) => a.type == AddressType.nativeSegwit).toList();

      if (segwit.isEmpty) {
        emit(
          const SigningState(
            status: SigningStatus.error,
            errorMessage: 'No native SegWit addresses found. Generate some first.',
          ),
        );

        return;
      }

      _addressIndexMap
        ..clear()
        ..addEntries(segwit.map((a) => MapEntry(a.value, a.index)));

      final utxos = await _scanUtxos(segwit.map((a) => a.value).toList());
      if (isClosed) return;

      emit(SigningState(status: SigningStatus.scanned, utxos: utxos));
    } catch (e) {
      if (isClosed) return;

      emit(
        SigningState(
          status: SigningStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSignAndBroadcast(
    SignAndBroadcastRequested event,
    Emitter<SigningState> emit,
  ) async {
    final utxos = state.utxos;
    if (utxos.isEmpty) {
      emit(
        state.copyWith(
          status: SigningStatus.error,
          errorMessage: 'No UTXOs to spend. Scan first.',
        ),
      );

      return;
    }

    emit(state.copyWith(status: SigningStatus.signing));
    try {
      final inputs = utxos.map((utxo) {
        final address = utxo.address;
        final index = address != null ? _addressIndexMap[address] : null;
        if (index == null) {
          throw StateError(
            'Cannot resolve derivation index for UTXO ${utxo.txid}:${utxo.vout}',
          );
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
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          status: SigningStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
