import 'package:wallet/wallet.dart';

sealed class AddressAction {}

/// An address operation failed (list or generate).
final class AddressErrorOccurredAction extends AddressAction {
  final AddressException exception;

  AddressErrorOccurredAction({required this.exception});
}
