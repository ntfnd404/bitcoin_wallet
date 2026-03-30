import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  late Bip39ServiceImpl service;

  setUp(() => service = const Bip39ServiceImpl());

  group('Bip39ServiceImpl', () {
    group('generateMnemonic', () {
      test('generates 12 words by default', () {
        final mnemonic = service.generateMnemonic();

        expect(mnemonic.words, hasLength(12));
      });

      test('generates 24 words when requested', () {
        final mnemonic = service.generateMnemonic(wordCount: 24);

        expect(mnemonic.words, hasLength(24));
      });

      test('throws ArgumentError for unsupported word count', () {
        expect(
          () => service.generateMnemonic(wordCount: 15),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('all words are in BIP39 wordlist', () {
        final mnemonic = service.generateMnemonic();

        for (final word in mnemonic.words) {
          expect(
            bip39EnglishWordlist.contains(word),
            isTrue,
            reason: 'Word "$word" not in BIP39 wordlist',
          );
        }
      });

      test('returns unmodifiable list', () {
        final mnemonic = service.generateMnemonic();

        expect(
          () => mnemonic.words.add('test'),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('validateMnemonic', () {
      test('validates generated 12-word mnemonic', () {
        final mnemonic = service.generateMnemonic();

        expect(service.validateMnemonic(mnemonic), isTrue);
      });

      test('validates generated 24-word mnemonic', () {
        final mnemonic = service.generateMnemonic(wordCount: 24);

        expect(service.validateMnemonic(mnemonic), isTrue);
      });

      test('rejects tampered mnemonic', () {
        final mnemonic = service.generateMnemonic();
        final tampered = List<String>.from(mnemonic.words);
        tampered[0] = tampered[0] == 'abandon' ? 'ability' : 'abandon';

        expect(
          service.validateMnemonic(Mnemonic(words: tampered)),
          isFalse,
        );
      });

      test('rejects unknown word', () {
        final mnemonic = service.generateMnemonic();
        final tampered = List<String>.from(mnemonic.words);
        tampered[0] = 'notaword';

        expect(
          service.validateMnemonic(Mnemonic(words: tampered)),
          isFalse,
        );
      });

      test('rejects wrong word count', () {
        expect(
          service.validateMnemonic(const Mnemonic(words: ['abandon'])),
          isFalse,
        );
      });

      test('validates known BIP39 test vector', () {
        // BIP39 test vector: 128-bit all-zero entropy
        // Entropy: 00000000000000000000000000000000
        // Expected: abandon abandon abandon abandon abandon abandon
        //           abandon abandon abandon abandon abandon about
        const knownMnemonic = Mnemonic(words: [
          'abandon', 'abandon', 'abandon', 'abandon',
          'abandon', 'abandon', 'abandon', 'abandon',
          'abandon', 'abandon', 'abandon', 'about',
        ]);

        expect(service.validateMnemonic(knownMnemonic), isTrue);
      });
    });
  });
}
