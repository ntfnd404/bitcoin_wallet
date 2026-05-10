import 'package:address/address.dart';

final class AddressState {
  final List<Address> addresses;
  final AddressStatus status;
  final Address? lastGenerated;
  final Exception? exception;

  const AddressState({
    this.addresses = const [],
    this.status = AddressStatus.initial,
    this.lastGenerated,
    this.exception,
  });

  AddressState copyWith({
    List<Address>? addresses,
    AddressStatus? status,
    Address? lastGenerated,
    Exception? exception,
    bool clearLastGenerated = false,
    bool clearException = false,
  }) => AddressState(
    addresses: addresses ?? this.addresses,
    status: status ?? this.status,
    lastGenerated: clearLastGenerated ? null : (lastGenerated ?? this.lastGenerated),
    exception: clearException ? null : (exception ?? this.exception),
  );
}

enum AddressStatus {
  initial,
  loading,
  loaded,
  generating,
  error,
}
