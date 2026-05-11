import 'package:address/address.dart';

sealed class AddressAction {}

/// An address operation failed (list or generate).
final class AddressErrorOccurred extends AddressAction {
  final AddressException exception;

  AddressErrorOccurred({required this.exception});
}
