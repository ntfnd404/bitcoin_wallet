import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/wallet.dart';

sealed class AddressEvent {
  const AddressEvent();
}

final class AddressListRequested extends AddressEvent {
  final Wallet wallet;

  const AddressListRequested({required this.wallet});
}

final class AddressGenerateRequested extends AddressEvent {
  final Wallet wallet;
  final AddressType type;

  const AddressGenerateRequested({required this.wallet, required this.type});
}
