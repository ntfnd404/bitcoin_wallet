import 'package:keys/keys.dart';
import 'package:keys/src/data/bip39_service_impl.dart';
import 'package:keys/src/data/key_derivation_service_impl.dart';
import 'package:keys/src/data/seed_repository_impl.dart';
import 'package:keys/src/data/transaction_signing_service_impl.dart';
import 'package:shared_kernel/shared_kernel.dart';

final class KeysAssembly {
  final Bip39Service bip39Service;
  final KeyDerivationService keyDerivationService;
  final SeedRepository seedRepository;
  final GetXpubUseCase getXpub;
  final SignTransactionUseCase signTransaction;

  factory KeysAssembly({
    required SecureStorage storage,
    required BitcoinNetwork network,
  }) {
    final derivation = KeyDerivationServiceImpl(network: network);
    final seeds = SeedRepositoryImpl(storage: storage);
    const signing = TransactionSigningServiceImpl();

    return KeysAssembly._(
      bip39Service: const Bip39ServiceImpl(),
      keyDerivationService: derivation,
      seedRepository: seeds,
      getXpub: GetXpubUseCase(
        seedRepository: seeds,
        derivation: derivation,
      ),
      signTransaction: SignTransactionUseCase(
        seedRepository: seeds,
        derivation: derivation,
        signing: signing,
      ),
    );
  }

  const KeysAssembly._({
    required this.bip39Service,
    required this.keyDerivationService,
    required this.seedRepository,
    required this.getXpub,
    required this.signTransaction,
  });
}
