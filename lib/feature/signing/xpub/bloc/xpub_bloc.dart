import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/feature/signing/xpub/bloc/xpub_event.dart';
import 'package:bitcoin_wallet/feature/signing/xpub/bloc/xpub_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keys/keys.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// BLoC for loading account xpubs for all address types of an HD wallet.
final class XpubBloc extends Bloc<XpubEvent, XpubState> {
  final GetXpubUseCase _getXpub;

  XpubBloc({required GetXpubUseCase getXpub})
      : _getXpub = getXpub,
        super(const XpubState()) {
    on<XpubLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    XpubLoadRequested event,
    Emitter<XpubState> emit,
  ) async {
    emit(state.copyWith(status: FetchStatus.loading));
    try {
      final results = <AddressType, AccountXpub>{};
      for (final type in AddressType.values) {
        results[type] = await _getXpub(event.walletId, type);
      }

      emit(state.copyWith(status: FetchStatus.loaded, xpubs: results));
    } catch (e) {
      emit(state.copyWith(
        status: FetchStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
