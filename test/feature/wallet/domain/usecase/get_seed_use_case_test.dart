import 'package:bitcoin_wallet/feature/wallet/domain/usecase/get_seed_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_seed_repository.dart';
import 'fakes/test_fixtures.dart';

void main() {
  group('GetSeedUseCase', () {
    late FakeSeedRepository seedRepo;
    late GetSeedUseCase useCase;

    setUp(() {
      seedRepo = FakeSeedRepository();
      useCase = GetSeedUseCase(seedRepository: seedRepo);
    });

    test('returns null when no seed stored for wallet', () async {
      final seed = await useCase('unknown-id');

      expect(seed, isNull);
    });

    test('returns stored seed for the given wallet id', () async {
      await seedRepo.storeSeed('w1', kTestMnemonic);

      final seed = await useCase('w1');

      expect(seed?.words, kTestMnemonic.words);
    });

    test('returns null for a different wallet id', () async {
      await seedRepo.storeSeed('w1', kTestMnemonic);

      final seed = await useCase('w2');

      expect(seed, isNull);
    });

    test('returns updated seed after overwrite', () async {
      final updated = kTestMnemonic;
      await seedRepo.storeSeed('w1', kTestMnemonic);
      await seedRepo.storeSeed('w1', updated);

      final seed = await useCase('w1');

      expect(seed?.words, updated.words);
    });
  });
}
