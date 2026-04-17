import 'package:keys/keys.dart';
import 'package:keys/src/data/bip39_service_impl.dart';
import 'package:keys/src/data/key_derivation_service_impl.dart';
import 'package:keys/src/data/seed_repository_impl.dart';
import 'package:shared_kernel/shared_kernel.dart';

final class KeysAssembly {
  final Bip39Service bip39Service;
  final KeyDerivationService keyDerivationService;
  final SeedRepository seedRepository;

  KeysAssembly({
    required SecureStorage storage,
    required BitcoinNetwork network,
  }) : bip39Service = const Bip39ServiceImpl(),
       keyDerivationService = KeyDerivationServiceImpl(network: network),
       seedRepository = SeedRepositoryImpl(storage: storage);
}
