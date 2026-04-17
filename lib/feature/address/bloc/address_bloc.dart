import 'package:address/address.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_event.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final AddressRepository _addressRepository;
  final GenerateAddressUseCase _generateAddress;

  AddressBloc({
    required AddressRepository addressRepository,
    required GenerateAddressUseCase generateAddress,
  })  : _addressRepository = addressRepository,
        _generateAddress = generateAddress,
        super(const AddressState()) {
    on<AddressListRequested>(_onAddressListRequested);
    on<AddressGenerateRequested>(_onAddressGenerateRequested);
  }

  Future<void> _onAddressListRequested(
    AddressListRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(status: AddressStatus.loading, clearErrorMessage: true));
    try {
      final addresses = await _addressRepository.getAddresses(event.wallet.id);
      if (isClosed) return;

      emit(state.copyWith(status: AddressStatus.loaded, addresses: addresses));
    } catch (e) {
      if (isClosed) return;

      emit(state.copyWith(status: AddressStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onAddressGenerateRequested(
    AddressGenerateRequested event,
    Emitter<AddressState> emit,
  ) async {
    if (state.status == AddressStatus.generating) return;
    emit(state.copyWith(status: AddressStatus.generating, clearErrorMessage: true));
    try {
      final address = await _generateAddress(event.wallet, event.type);
      if (isClosed) return;

      emit(
        state.copyWith(
          status: AddressStatus.loaded,
          addresses: [...state.addresses, address],
          lastGenerated: address,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(state.copyWith(status: AddressStatus.error, errorMessage: e.toString()));
    }
  }
}
