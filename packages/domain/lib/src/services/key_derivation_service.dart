import 'package:domain/src/entities/address.dart';
import 'package:domain/src/entities/address_type.dart';
import 'package:domain/src/entities/mnemonic.dart';

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
  /// [walletId] associates the derived address with a wallet.
  Address deriveAddress(
    Mnemonic mnemonic,
    AddressType type,
    int index,
    String walletId,
  );
}
