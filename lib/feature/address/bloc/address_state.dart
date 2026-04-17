import 'package:address/address.dart';

final class AddressState {
  final List<Address> addresses;
  final AddressStatus status;
  final Address? lastGenerated;
  final String? errorMessage;

  const AddressState({
    this.addresses = const [],
    this.status = AddressStatus.initial,
    this.lastGenerated,
    this.errorMessage,
  });

  AddressState copyWith({
    List<Address>? addresses,
    AddressStatus? status,
    Address? lastGenerated,
    String? errorMessage,
    bool clearLastGenerated = false,
    bool clearErrorMessage = false,
  }) => AddressState(
    addresses: addresses ?? this.addresses,
    status: status ?? this.status,
    lastGenerated: clearLastGenerated ? null : (lastGenerated ?? this.lastGenerated),
    errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
  );
}

enum AddressStatus {
  initial,
  loading,
  loaded,
  generating,
  error,
}
