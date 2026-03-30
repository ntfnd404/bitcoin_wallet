import 'package:domain/domain.dart';
import 'package:rpc_client/rpc_client.dart';
import 'package:uuid/uuid.dart';

import '../local/wallet_local_store.dart';

/// [NodeWalletRepository] backed by Bitcoin Core RPC.
///
/// Wallet metadata and addresses are persisted via [WalletLocalStore].
/// All key management is delegated to Bitcoin Core.
final class NodeWalletRepositoryImpl implements NodeWalletRepository {
  const NodeWalletRepositoryImpl({
    required BitcoinRpcClient rpcClient,
    required WalletLocalStore localStore,
  }) : _rpcClient = rpcClient,
       _localStore = localStore;

  final BitcoinRpcClient _rpcClient;
  final WalletLocalStore _localStore;

  static const _uuid = Uuid();

  @override
  Future<Wallet> createNodeWallet(String name) async {
    await _rpcClient.call('createwallet', [name]);
    final wallet = Wallet(
      id: _uuid.v4(),
      name: name,
      type: WalletType.node,
      createdAt: DateTime.now().toUtc(),
    );
    await _localStore.saveWallet(wallet);

    return wallet;
  }

  @override
  Future<List<Wallet>> getWallets() => _localStore.getWallets();

  @override
  Future<Address> generateAddress(Wallet wallet, AddressType type) async {
    final result = await _rpcClient.call(
      'getnewaddress',
      ['', _rpcAddressType(type)],
      wallet.name,
    );
    final index = await _localStore.nextAddressIndex(wallet.id);
    final address = Address(
      value: result as String,
      type: type,
      walletId: wallet.id,
      index: index,
    );
    await _localStore.saveAddress(address);

    return address;
  }

  @override
  Future<List<Address>> getAddresses(Wallet wallet) => _localStore.getAddresses(wallet.id);

  String _rpcAddressType(AddressType type) => switch (type) {
    AddressType.legacy => 'legacy',
    AddressType.wrappedSegwit => 'p2sh-segwit',
    AddressType.nativeSegwit => 'bech32',
    AddressType.taproot => 'bech32m',
  };
}
