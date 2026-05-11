import 'package:address/address.dart';

final class AddressState {
  final List<Address> addresses;
  final AddressStatus status;

  const AddressState({
    this.addresses = const [],
    this.status = AddressStatus.initial,
  });

  AddressState copyWith({
    List<Address>? addresses,
    AddressStatus? status,
  }) => AddressState(
    addresses: addresses ?? this.addresses,
    status: status ?? this.status,
  );
}

enum AddressStatus {
  initial,
  loading,
  loaded,
  generating,
  error,
}
