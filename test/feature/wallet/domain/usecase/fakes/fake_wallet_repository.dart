import 'package:domain/domain.dart';

/// In-memory wallet repository for unit tests.
final class FakeWalletRepository implements WalletRepository {
  final List<Wallet> _wallets = [];

  List<Wallet> get saved => List.unmodifiable(_wallets);

  @override
  Future<void> saveWallet(Wallet wallet) async => _wallets.add(wallet);

  @override
  Future<List<Wallet>> getWallets() async => List.unmodifiable(_wallets);
}
