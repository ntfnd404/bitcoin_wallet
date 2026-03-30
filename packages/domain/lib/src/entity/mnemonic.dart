/// Immutable wrapper around a BIP39 word list.
///
/// Does not override [toString] — prevents accidental logging of seed words.
final class Mnemonic {
  const Mnemonic({required this.words});

  final List<String> words;
}
