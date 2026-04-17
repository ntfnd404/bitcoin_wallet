import 'package:keys/src/domain/entity/derived_address.dart';
import 'package:keys/src/domain/entity/mnemonic.dart';
import 'package:shared_kernel/shared_kernel.dart';

abstract interface class KeyDerivationService {
  /// Derives a Bitcoin address from [mnemonic] at [type] and [index].
  ///
  /// Derivation paths (coin_type depends on active [BitcoinNetwork]):
  /// - legacy         → m/44'/[coinType]'/0'/0/[index]
  /// - wrappedSegwit  → m/49'/[coinType]'/0'/0/[index]
  /// - nativeSegwit   → m/84'/[coinType]'/0'/0/[index]
  /// - taproot        → m/86'/[coinType]'/0'/0/[index]
  ///
  /// [index] must be >= 0.
  DerivedAddress deriveAddress(
    Mnemonic mnemonic,
    AddressType type,
    int index,
  );
}
