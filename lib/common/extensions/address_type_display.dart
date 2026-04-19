import 'package:shared_kernel/shared_kernel.dart';

/// Presentation labels for [AddressType].
extension AddressTypeDisplay on AddressType {
  /// Short label — suitable for list tiles and compact displays.
  String get shortLabel => switch (this) {
    AddressType.legacy => 'P2PKH',
    AddressType.wrappedSegwit => 'P2SH-SegWit',
    AddressType.nativeSegwit => 'SegWit',
    AddressType.taproot => 'Taproot',
  };

  /// Full label — includes script type and encoding notes.
  String get fullLabel => switch (this) {
    AddressType.legacy => 'P2PKH (Legacy)',
    AddressType.wrappedSegwit => 'P2SH-SegWit (Wrapped)',
    AddressType.nativeSegwit => 'Native SegWit (bech32)',
    AddressType.taproot => 'Taproot (bech32m)',
  };
}
