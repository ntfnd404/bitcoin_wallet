import 'package:shared_kernel/shared_kernel.dart';

/// Maps Bitcoin Core RPC type strings to [AddressType].
///
/// Single source of truth for script/descriptor type parsing.
/// Throws [ArgumentError] on unknown values to fail fast.
abstract final class AddressTypeRpcMapper {
  static AddressType fromScriptType(String type) =>
      switch (type) {
        'pubkeyhash' => AddressType.legacy,
        'scripthash' => AddressType.wrappedSegwit,
        'witness_v0_keyhash' => AddressType.nativeSegwit,
        'witness_v0_scripthash' => AddressType.nativeSegwit,
        'witness_v1_taproot' => AddressType.taproot,
        _ => throw ArgumentError('Unknown scriptPubKey type: $type'),
      };

  static AddressType fromDescriptor(String desc) {
    if (desc.startsWith('tr(')) return AddressType.taproot;
    if (desc.startsWith('wpkh(')) return AddressType.nativeSegwit;
    if (desc.startsWith('sh(wpkh(')) return AddressType.wrappedSegwit;
    if (desc.startsWith('pkh(')) return AddressType.legacy;

    throw ArgumentError('Unknown descriptor: $desc');
  }
}
