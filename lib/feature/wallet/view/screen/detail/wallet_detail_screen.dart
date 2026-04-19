import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/core/routing/app_router.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_bloc.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_event.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_state.dart';
import 'package:bitcoin_wallet/feature/address/di/address_scope.dart';
import 'package:bitcoin_wallet/feature/address/view/widget/address_type_section.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_bloc.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_event.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/wallet.dart';

/// Shows addresses for a single wallet grouped by [AddressType].
///
/// Creates its own [AddressBloc] via [AddressScope] factory — each instance
/// owns an isolated address BLoC with its own lifecycle.
/// Navigates to [AddressScreen] and [SeedPhraseScreen] via [AppRouter].
class WalletDetailScreen extends StatefulWidget {
  const WalletDetailScreen({
    super.key,
    required this.wallet,
  });

  final Wallet wallet;

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  late final AddressBloc _addressBloc;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _addressBloc = AddressScope.newAddressBloc(context);
      _addressBloc.add(AddressListRequested(wallet: widget.wallet));
    }
  }

  @override
  void dispose() {
    _addressBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<AddressBloc>.value(
    value: _addressBloc,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.wallet.name),
        actions: [
          if (widget.wallet.isHd)
            Semantics(
              label: 'View seed phrase',
              button: true,
              child: TextButton(
                onPressed: () {
                  context.read<WalletBloc>().add(SeedViewRequested(walletId: widget.wallet.id));
                },
                child: const Text('View Seed'),
              ),
            ),
        ],
      ),
      body: BlocListener<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state.status == WalletStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Unknown error')),
            );
          }
          if (state.status == WalletStatus.awaitingSeedConfirmation) {
            final mnemonic = state.pendingMnemonic;
            if (mnemonic != null) {
              AppRouter.toSeedPhrase(context, mnemonic, widget.wallet.id);
            }
          }
        },
        child: BlocConsumer<AddressBloc, AddressState>(
          listener: (context, state) {
            if (state.status == AddressStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage ?? 'Unknown error')),
              );
            }
          },
          builder: (context, state) {
            if (state.status == AddressStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final isGenerating = state.status == AddressStatus.generating;

            return ListView(
              children: [
                ListTile(
                  title: const Text('Transaction History'),
                  leading: const Icon(Icons.history),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => AppRouter.toTransactionList(context, widget.wallet),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Unspent Outputs'),
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => AppRouter.toUtxoList(context, widget.wallet),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Send'),
                  leading: const Icon(Icons.send),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => AppRouter.toSend(context, widget.wallet),
                ),
                const Divider(height: 1),
                _MineBlockTile(wallet: widget.wallet),
                const Divider(height: 1),
                if (widget.wallet.isHd) ...[
                  ListTile(
                    title: const Text('Account xpubs'),
                    leading: const Icon(Icons.key_outlined),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => AppRouter.toXpub(context, widget.wallet),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Sign & Send (demo)'),
                    leading: const Icon(Icons.send_outlined),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => AppRouter.toSigningDemo(context, widget.wallet),
                  ),
                  const Divider(height: 1),
                ],
                ...AddressType.values.map((type) {
                  final filtered = state.addresses.where((a) => a.type == type).toList();

                  return AddressTypeSection(
                    type: type,
                    addresses: filtered,
                    isGenerating: isGenerating,
                    onGenerate: () => context.read<AddressBloc>().add(
                      AddressGenerateRequested(wallet: widget.wallet, type: type),
                    ),
                    onAddressSelected: (addr) => AppRouter.toAddress(context, addr),
                  );
                }),
              ],
            );
          },
        ),
      ),
    ),
  );

}

/// Dev-only tile that mines one block, crediting the coinbase to this wallet.
///
/// For Node wallets uses [NodeTransactionDataSource.getNewAddress]; for HD
/// wallets uses the first stored nativeSegwit address. Shows a snack bar on
/// success/failure.
class _MineBlockTile extends StatefulWidget {
  const _MineBlockTile({required this.wallet});

  final Wallet wallet;

  @override
  State<_MineBlockTile> createState() => _MineBlockTileState();
}

class _MineBlockTileState extends State<_MineBlockTile> {
  bool _isMining = false;

  Future<void> _mine() async {
    setState(() => _isMining = true);

    try {
      final deps = AppScope.of(context);
      final blockGen = deps.transaction.blockGeneration;

      // Resolve target address.
      final String toAddress;
      if (widget.wallet.isNode) {
        toAddress = await deps.transaction.prepareNodeSend
            // Reuse NodeTransactionDataSource.getNewAddress via the assembly.
            // We call it through the existing PrepareNodeSendUseCase's data source
            // by generating one address. Since we can't access the data source
            // directly, we use the address assembly instead.
            .call(
              walletName: widget.wallet.name,
              targetSat: const Satoshi(1),
              feeRateSatPerVbyte: 1,
            )
            .then((prep) => prep.changeAddress);
      } else {
        final addresses = await deps.address.addressRepository
            .getAddresses(widget.wallet.id);
        final native = addresses
            .where((a) => a.type == AddressType.nativeSegwit)
            .toList();
        toAddress = native.isNotEmpty ? native.first.value : '';
      }

      if (toAddress.isEmpty) {
        _showSnack('No address available to mine to');

        return;
      }

      await blockGen.generateToAddress(1, toAddress);
      _showSnack('Block mined!');
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isMining = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('Mine 1 block (dev)'),
        leading: _isMining
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.construction_outlined),
        onTap: _isMining ? null : _mine,
      );
}
