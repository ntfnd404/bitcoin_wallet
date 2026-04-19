import 'package:shared_kernel/shared_kernel.dart';

/// Adds RPC serialization to [AddressType].
extension AddressTypeRpc on AddressType {
  /// Maps [AddressType] to Bitcoin Core `getnewaddress` type parameter.
  String get rpcAddressTypeParam =>
      switch (this) {
        AddressType.legacy => 'legacy',
        AddressType.wrappedSegwit => 'p2sh-segwit',
        AddressType.nativeSegwit => 'bech32',
        AddressType.taproot => 'bech32m',
      };
}
