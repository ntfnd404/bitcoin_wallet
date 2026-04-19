import 'package:shared_kernel/shared_kernel.dart';

/// A single HD-wallet address with its derivation metadata.
///
/// Used by [PrepareHdSendUseCase] to match scanned UTXOs to their signing context.
final class HdAddressEntry {
  final String address;
  final int index;
  final AddressType type;

  const HdAddressEntry({
    required this.address,
    required this.index,
    required this.type,
  });
}
