import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_action.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_event.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/wallet.dart';

final class AddressBloc extends Bloc<AddressEvent, AddressState> with ActionBlocMixin<AddressState, AddressAction> {
  final AddressRepository _addressRepository;
  final GenerateAddressUseCase _generateAddress;

  AddressBloc({
    required AddressRepository addressRepository,
    required GenerateAddressUseCase generateAddress,
  }) : _addressRepository = addressRepository,
       _generateAddress = generateAddress,
       super(const AddressState()) {
    on<AddressListRequested>(_onAddressListRequested);
    on<AddressGenerateRequested>(_onAddressGenerateRequested);
  }

  Future<void> _onAddressListRequested(
    AddressListRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(status: AddressStatus.processing));
    try {
      final addresses = await _addressRepository.getAddresses(event.wallet.id);
      if (isClosed) return;

      emit(state.copyWith(status: AddressStatus.idle, addresses: addresses));
    } on AddressException catch (e) {
      if (isClosed) return;
      emitAction(AddressErrorOccurred(exception: e));
      emit(state.copyWith(status: AddressStatus.idle));
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: AddressStatus.idle));
    }
  }

  Future<void> _onAddressGenerateRequested(
    AddressGenerateRequested event,
    Emitter<AddressState> emit,
  ) async {
    if (state.status == AddressStatus.processing) return;
    emit(state.copyWith(status: AddressStatus.processing));
    try {
      final address = await _generateAddress(event.wallet, event.type);
      if (isClosed) return;

      emit(state.copyWith(status: AddressStatus.idle, addresses: [...state.addresses, address]));
    } on AddressException catch (e) {
      if (isClosed) return;
      emitAction(AddressErrorOccurred(exception: e));
      emit(state.copyWith(status: AddressStatus.idle));
    } catch (e, stack) {
      addError(e, stack);
      if (isClosed) return;
      emit(state.copyWith(status: AddressStatus.idle));
    }
  }
}
