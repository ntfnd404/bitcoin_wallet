import 'package:wallet/wallet.dart';

/// In-memory wallet repository for unit tests.
final class FakeWalletRepository implements HdWalletRepository {
  final List<Wallet> _wallets = [];

  List<Wallet> get saved => List.unmodifiable(_wallets);

  @override
  Future<void> saveWallet(HdWallet wallet) async => _wallets.add(wallet);

  @override
  Future<List<Wallet>> getWallets() async => List.unmodifiable(_wallets);
}
