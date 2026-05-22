import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/core/routing/app_router.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_action.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_bloc.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_event.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_state.dart';
import 'package:bitcoin_wallet/feature/address/di/address_scope.dart';
import 'package:bitcoin_wallet/feature/address/view/widget/address_type_section.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_bloc.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/di/regtest_mining_scope.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_action.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_bloc.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_event.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_state.dart';
import 'package:bitcoin_wallet/feature/wallet/view/widget/mine_block_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/wallet.dart';

/// Shows addresses for a single wallet grouped by [AddressType].
///
/// Creates its own [AddressBloc] via [AddressScope] factory — each instance
/// owns an isolated address BLoC with its own lifecycle.
/// Navigates to [AddressScreen] and [SeedPhraseScreen] via [AppRouter].
class WalletDetailScreen extends StatelessWidget {
  const WalletDetailScreen({
    super.key,
    required this.wallet,
  });

  final Wallet wallet;

  @override
  Widget build(BuildContext context) => BlocProvider<AddressBloc>(
    create: (ctx) => AddressScope.newAddressBloc(ctx)..add(AddressListRequested(wallet: wallet)),
    child: Scaffold(
      appBar: AppBar(
        title: Text(wallet.name),
        actions: [
          if (wallet is HdWallet)
            Semantics(
              label: 'View seed phrase',
              button: true,
              child: TextButton(
                onPressed: () {
                  context.read<WalletBloc>().add(SeedViewRequested(walletId: wallet.id));
                },
                child: const Text('View Seed'),
              ),
            ),
        ],
      ),
      body: ActionBlocListener<WalletBloc, WalletState, WalletAction>(
        listener: (context, action) {
          switch (action) {
            case WalletSeedReadyAction(:final mnemonic):
              AppRouter.toSeedPhrase(context, mnemonic, wallet.id);
            case WalletErrorOccurredAction(:final exception):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(exception.toString())),
              );
            case WalletSeedFailedAction(:final exception):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(exception.toString())),
              );
            case _:
              break;
          }
        },
        child: ActionBlocListener<AddressBloc, AddressState, AddressAction>(
          listener: (context, action) {
            switch (action) {
              case AddressErrorOccurredAction(:final exception):
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(exception.toString())),
                );
            }
          },
          child: BlocBuilder<AddressBloc, AddressState>(
            builder: (context, state) {
              if (state.status == AddressStatus.processing) {
                return const Center(child: CircularProgressIndicator());
              }

              final isGenerating = state.status == AddressStatus.processing;

              return ListView(
                children: [
                  ListTile(
                    title: const Text('Transaction History'),
                    leading: const Icon(Icons.history),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => AppRouter.toTransactionList(context, wallet),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Unspent Outputs'),
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => AppRouter.toUtxoList(context, wallet),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Send'),
                    leading: const Icon(Icons.send),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => AppRouter.toSend(context, wallet),
                  ),
                  const Divider(height: 1),
                  if (wallet is NodeWallet) ...[
                    ListTile(
                      title: const Text('Send with manual UTXO selection'),
                      leading: const Icon(Icons.checklist_outlined),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => AppRouter.toUtxoPicker(context, wallet as NodeWallet),
                    ),
                    const Divider(height: 1),
                  ],
                  RegtestMiningScope(
                    child: BlocProvider<RegtestMiningBloc>(
                      create: (ctx) => RegtestMiningScope.newBloc(ctx, wallet.id),
                      child: MineBlockTile(wallet: wallet),
                    ),
                  ),
                  const Divider(height: 1),
                  if (wallet is HdWallet) ...[
                    ListTile(
                      title: const Text('Account xpubs'),
                      leading: const Icon(Icons.key_outlined),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => AppRouter.toXpub(context, wallet),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Sign & Send (demo)'),
                      leading: const Icon(Icons.send_outlined),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => AppRouter.toSigningDemo(context, wallet),
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
                        AddressGenerateRequested(wallet: wallet, type: type),
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
    ),
  );
}
