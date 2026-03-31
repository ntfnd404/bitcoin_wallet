import 'package:data/data.dart';
import 'package:data/src/crypto/bip32.dart';
import 'package:data/src/crypto/hash_utils.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  late KeyDerivationServiceImpl service;

  setUp(() => service = const KeyDerivationServiceImpl());

  // BIP39 all-zero entropy → known test mnemonic
  const testMnemonic = Mnemonic(words: [
    'abandon', 'abandon', 'abandon', 'abandon',
    'abandon', 'abandon', 'abandon', 'abandon',
    'abandon', 'abandon', 'abandon', 'about',
  ]);

  group('BIP39 seed derivation', () {
    test('produces correct seed from known mnemonic', () {
      final seed = mnemonicToSeed(testMnemonic.words);
      final seedHex = bytesToHex(seed);

      expect(
        seedHex,
        '5eb00bbddcf069084889a8ab9155568165f5c453'
        'ccb85e70811aaed6f6da5fc19a5ac40b389cd370'
        'd086206dec8aa6c43daea6690f20ad3d8d48b2d2'
        'ce9e38e4',
      );
    });
  });

  group('BIP32 master key derivation', () {
    test('produces correct master key from test vector 1', () {
      final seed = hexToBytes('000102030405060708090a0b0c0d0e0f');
      final master = deriveMasterKey(seed);

      expect(
        bytesToHex(master.privateKey),
        'e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35',
      );
      expect(
        bytesToHex(master.chainCode),
        '873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508',
      );
    });

    test('derives correct child key m/0h from test vector 1', () {
      final seed = hexToBytes('000102030405060708090a0b0c0d0e0f');
      final master = deriveMasterKey(seed);
      final child = deriveKeyPath(master, [0x80000000]);

      expect(
        bytesToHex(child.privateKey),
        'edb2e14f9ee77d26dd93b4ecede8d16ed408ce149b6cd80b0715a2d911a0afea',
      );
      expect(
        bytesToHex(child.chainCode),
        '47fdacbd0f1097043b78c63c20c34ef4ed9a111d980047ad16282c7ae6236141',
      );
    });

    test('derives correct public key from test vector 1 master', () {
      final seed = hexToBytes('000102030405060708090a0b0c0d0e0f');
      final master = deriveMasterKey(seed);
      final pubKey = privateKeyToPublic(master.privateKey);

      expect(
        bytesToHex(pubKey),
        '0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2',
      );
    });
  });

  group('KeyDerivationServiceImpl', () {
    group('address prefixes', () {
      test('legacy address starts with m or n', () {
        final address = service.deriveAddress(
          testMnemonic, AddressType.legacy, 0,
        );

        expect(address.value[0], anyOf('m', 'n'));
      });

      test('wrapped segwit address starts with 2', () {
        final address = service.deriveAddress(
          testMnemonic, AddressType.wrappedSegwit, 0,
        );

        expect(address.value, startsWith('2'));
      });

      test('native segwit address starts with bcrt1q', () {
        final address = service.deriveAddress(
          testMnemonic, AddressType.nativeSegwit, 0,
        );

        expect(address.value, startsWith('bcrt1q'));
      });

      test('taproot address starts with bcrt1p', () {
        final address = service.deriveAddress(
          testMnemonic, AddressType.taproot, 0,
        );

        expect(address.value, startsWith('bcrt1p'));
      });
    });

    group('address lengths', () {
      test('native segwit address is 44 characters', () {
        final address = service.deriveAddress(
          testMnemonic, AddressType.nativeSegwit, 0,
        );

        expect(address.value.length, 44);
      });

      test('taproot address is 64 characters', () {
        final address = service.deriveAddress(
          testMnemonic, AddressType.taproot, 0,
        );

        expect(address.value.length, 64);
      });
    });

    group('derivation paths', () {
      test('legacy path is m/44h/1h/0h/0/index', () {
        final address = service.deriveAddress(
          testMnemonic, AddressType.legacy, 3,
        );

        expect(address.derivationPath, "m/44'/1'/0'/0/3");
      });

      test('wrapped segwit path is m/49h/1h/0h/0/index', () {
        final address = service.deriveAddress(
          testMnemonic, AddressType.wrappedSegwit, 0,
        );

        expect(address.derivationPath, "m/49'/1'/0'/0/0");
      });

      test('native segwit path is m/84h/1h/0h/0/index', () {
        final address = service.deriveAddress(
          testMnemonic, AddressType.nativeSegwit, 5,
        );

        expect(address.derivationPath, "m/84'/1'/0'/0/5");
      });

      test('taproot path is m/86h/1h/0h/0/index', () {
        final address = service.deriveAddress(
          testMnemonic, AddressType.taproot, 0,
        );

        expect(address.derivationPath, "m/86'/1'/0'/0/0");
      });
    });

    group('determinism', () {
      test('same mnemonic and index produce identical address', () {
        final a1 = service.deriveAddress(
          testMnemonic, AddressType.nativeSegwit, 0,
        );
        final a2 = service.deriveAddress(
          testMnemonic, AddressType.nativeSegwit, 0,
        );

        expect(a1.value, a2.value);
      });

      test('different indexes produce different addresses', () {
        final a0 = service.deriveAddress(
          testMnemonic, AddressType.nativeSegwit, 0,
        );
        final a1 = service.deriveAddress(
          testMnemonic, AddressType.nativeSegwit, 1,
        );

        expect(a0.value, isNot(a1.value));
      });

      test('different types produce different addresses', () {
        final legacy = service.deriveAddress(
          testMnemonic, AddressType.legacy, 0,
        );
        final segwit = service.deriveAddress(
          testMnemonic, AddressType.nativeSegwit, 0,
        );

        expect(legacy.value, isNot(segwit.value));
      });
    });

    group('address metadata', () {
      test('sets correct type and index', () {
        final address = service.deriveAddress(
          testMnemonic, AddressType.taproot, 7,
        );

        expect(address.type, AddressType.taproot);
        expect(address.index, 7);
      });

      test('sets empty walletId (caller fills via copyWith)', () {
        final address = service.deriveAddress(
          testMnemonic, AddressType.legacy, 0,
        );

        expect(address.walletId, '');
      });
    });

    group('validation', () {
      test('throws for negative index', () {
        expect(
          () => service.deriveAddress(testMnemonic, AddressType.legacy, -1),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
