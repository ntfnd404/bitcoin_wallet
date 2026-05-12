import 'package:shared_kernel/shared_kernel.dart';

/// Outbound port for address generation on Bitcoin Core node.
abstract interface class NodeAddressGateway {
  /// Asks Bitcoin Core to derive the next address of [type] for [walletName].
  Future<String> generateAddress(String walletName, AddressType type);
}
