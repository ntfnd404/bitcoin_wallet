/// Account-level extended public key for a single address type.
///
/// Contains the Base58Check-encoded xpub and the BIP32 derivation path
/// at which the account key sits (e.g. `m/84'/1'/0'` for BIP84 regtest).
final class AccountXpub {
  final String xpub;
  final String derivationPath;

  const AccountXpub({required this.xpub, required this.derivationPath});
}
