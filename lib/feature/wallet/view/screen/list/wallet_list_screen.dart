import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/core/routing/app_router.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_action.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_bloc.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_event.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_state.dart';
import 'package:bitcoin_wallet/feature/wallet/view/widget/wallet_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletListScreen extends StatefulWidget {
  const WalletListScreen({super.key});

  @override
  State<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends State<WalletListScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      context.read<WalletBloc>().add(const WalletListRequested());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Wallets')),
    floatingActionButton: Semantics(
      label: 'Create wallet',
      button: true,
      child: FloatingActionButton(
        onPressed: () => AppRouter.toCreateWallet(context),
        child: const Icon(Icons.add),
      ),
    ),
    body: ActionBlocConsumer<WalletBloc, WalletState, WalletAction>(
      listener: (context, action) {
        switch (action) {
          case WalletErrorOccurredAction(:final exception):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(exception.toString())),
            );
          case _:
            break;
        }
      },
      builder: (context, state) {
        if (state.status == WalletStatus.processing) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.wallets.isEmpty) {
          return const Center(child: Text('No wallets yet'));
        }

        return ListView.builder(
          itemCount: state.wallets.length,
          itemBuilder: (context, index) {
            final wallet = state.wallets[index];

            return WalletCard(
              wallet: wallet,
              onTap: () => AppRouter.toWalletDetail(context, wallet),
            );
          },
        );
      },
    ),
  );
}
