import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:domain/domain.dart';

import 'bip39_wordlist.dart';

/// BIP39 mnemonic generation and validation.
///
/// Uses `dart:math` [Random.secure] for entropy (OS CSPRNG)
/// and `package:crypto` SHA256 for checksum.
final class Bip39ServiceImpl implements Bip39Service {
  const Bip39ServiceImpl();

  static const _supportedWordCounts = {12, 24};

  @override
  Mnemonic generateMnemonic({int wordCount = 12}) {
    if (!_supportedWordCounts.contains(wordCount)) {
      throw ArgumentError.value(
        wordCount,
        'wordCount',
        'must be 12 or 24',
      );
    }
    final entropyBytes = wordCount == 12 ? 16 : 32; // 128 or 256 bits
    final entropy = _generateEntropy(entropyBytes);
    final words = _entropyToWords(entropy);

    return Mnemonic(words: List.unmodifiable(words));
  }

  @override
  bool validateMnemonic(Mnemonic mnemonic) {
    final words = mnemonic.words;
    if (!_supportedWordCounts.contains(words.length)) return false;

    // Look up each word → 11-bit index
    final bits = StringBuffer();
    for (final word in words) {
      final index = bip39EnglishWordlist.indexOf(word);
      if (index < 0) return false;
      bits.write(index.toRadixString(2).padLeft(11, '0'));
    }

    final bitString = bits.toString();
    final entropyBits = bitString.length - bitString.length ~/ 33;
    final checksumBits = bitString.length - entropyBits;

    // Extract entropy bytes
    final entropy = _bitsToBytes(bitString.substring(0, entropyBits));
    final expectedChecksum = bitString.substring(entropyBits);

    // Compute checksum from entropy
    final hash = sha256.convert(entropy);
    final hashBits =
        hash.bytes.map((b) => b.toRadixString(2).padLeft(8, '0')).join();
    final actualChecksum = hashBits.substring(0, checksumBits);

    return expectedChecksum == actualChecksum;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Uint8List _generateEntropy(int length) {
    final rng = Random.secure();

    return Uint8List.fromList(
      List.generate(length, (_) => rng.nextInt(256)),
    );
  }

  List<String> _entropyToWords(Uint8List entropy) {
    // SHA256 hash for checksum
    final hash = sha256.convert(entropy);
    final checksumBits = entropy.length ~/ 4; // entropy_bits / 32

    // Convert entropy to bit string
    final entropyBitString =
        entropy.map((b) => b.toRadixString(2).padLeft(8, '0')).join();

    // Convert hash to bit string and take first checksumBits
    final hashBitString =
        hash.bytes.map((b) => b.toRadixString(2).padLeft(8, '0')).join();
    final checksum = hashBitString.substring(0, checksumBits);

    // Concatenate entropy + checksum
    final combined = entropyBitString + checksum;

    // Split into 11-bit groups → wordlist index
    final wordCount = combined.length ~/ 11;
    final words = <String>[];
    for (var i = 0; i < wordCount; i++) {
      final segment = combined.substring(i * 11, (i + 1) * 11);
      final index = int.parse(segment, radix: 2);
      words.add(bip39EnglishWordlist[index]);
    }

    return words;
  }

  Uint8List _bitsToBytes(String bitString) {
    final byteCount = bitString.length ~/ 8;
    final bytes = Uint8List(byteCount);
    for (var i = 0; i < byteCount; i++) {
      bytes[i] = int.parse(bitString.substring(i * 8, (i + 1) * 8), radix: 2);
    }

    return bytes;
  }
}
