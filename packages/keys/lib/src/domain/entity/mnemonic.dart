/// Immutable wrapper around a BIP39 word list.
///
/// Does not override [toString] — prevents accidental logging of seed words.
final class Mnemonic {
  final List<String> words;

  Mnemonic({required this.words}) {
    if (words.length != 12 && words.length != 24) {
      throw ArgumentError(
        'BIP39 requires 12 or 24 words, got ${words.length}',
      );
    }
  }
}
