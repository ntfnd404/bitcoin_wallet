import 'package:keys/src/data/seed_repository_impl.dart';
import 'package:keys/src/domain/entity/mnemonic.dart';
import 'package:keys/src/domain/exception/keys_exception.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';

import 'fake_secure_storage.dart';
import 'mock_secure_storage.dart';

void main() {
  late FakeSecureStorage storage;
  late SeedRepositoryImpl repository;

  const walletId = 'test-wallet-id';
  final mnemonic = Mnemonic(
    words: [
      'abandon',
      'abandon',
      'abandon',
      'abandon',
      'abandon',
      'abandon',
      'abandon',
      'abandon',
      'abandon',
      'abandon',
      'abandon',
      'about',
    ],
  );

  setUp(() {
    storage = FakeSecureStorage();
    repository = SeedRepositoryImpl(storage: storage);
  });

  group('SeedRepositoryImpl', () {
    group('storeSeed + getSeed', () {
      test('stored seed is retrievable', () async {
        await repository.storeSeed(walletId, mnemonic);
        final result = await repository.getSeed(walletId);

        expect(result?.words, mnemonic.words);
      });

      test('returns null for unknown walletId', () async {
        final result = await repository.getSeed('unknown');

        expect(result, isNull);
      });

      test('overwrites existing seed for same walletId', () async {
        final other = Mnemonic(
          words: [
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'wrong',
          ],
        );
        await repository.storeSeed(walletId, mnemonic);
        await repository.storeSeed(walletId, other);
        final result = await repository.getSeed(walletId);

        expect(result?.words, other.words);
      });
    });

    group('deleteSeed', () {
      test('deleted seed returns null', () async {
        await repository.storeSeed(walletId, mnemonic);
        await repository.deleteSeed(walletId);
        final result = await repository.getSeed(walletId);

        expect(result, isNull);
      });

      test('deleting absent key does not throw', () async {
        await expectLater(
          repository.deleteSeed('nonexistent'),
          completes,
        );
      });
    });

    group('error wrapping (Phase 3)', () {
      late MockSecureStorage mockStorage;
      late SeedRepositoryImpl repo;

      setUp(() {
        mockStorage = MockSecureStorage();
        repo = SeedRepositoryImpl(storage: mockStorage);
      });

      test('storeSeed wraps storage failure as KeysStorageException', () async {
        when(
          () => mockStorage.setString(any(), any()),
        ).thenThrow(const SecureStorageException());

        await expectLater(
          () => repo.storeSeed(walletId, mnemonic),
          throwsA(isA<KeysStorageException>()),
        );

        verify(() => mockStorage.setString('seed_$walletId', any())).called(1);
      });

      test('getSeed wraps storage failure as KeysStorageException', () async {
        when(() => mockStorage.getString(any())).thenThrow(const SecureStorageException());

        await expectLater(
          () => repo.getSeed(walletId),
          throwsA(isA<KeysStorageException>()),
        );

        verify(() => mockStorage.getString('seed_$walletId')).called(1);
      });

      test('deleteSeed wraps storage failure as KeysStorageException', () async {
        when(() => mockStorage.remove(any())).thenThrow(const SecureStorageException());

        await expectLater(
          () => repo.deleteSeed(walletId),
          throwsA(isA<KeysStorageException>()),
        );

        verify(() => mockStorage.remove('seed_$walletId')).called(1);
      });
    });

    group('key isolation', () {
      test('different walletIds do not interfere', () async {
        const otherId = 'other-wallet-id';
        final other = Mnemonic(
          words: [
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'zoo',
            'wrong',
          ],
        );
        await repository.storeSeed(walletId, mnemonic);
        await repository.storeSeed(otherId, other);

        final first = await repository.getSeed(walletId);
        final second = await repository.getSeed(otherId);

        expect(first?.words, mnemonic.words);
        expect(second?.words, other.words);
      });
    });
  });
}
