import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_bloc.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_event.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_state.dart';
import 'package:bitcoin_wallet/feature/wallet/view/widget/wallet_card.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays a list of wallets loaded by [WalletBloc].
///
/// Receives navigation callbacks from the caller; owns no DI.
class WalletListScreen extends StatefulWidget {
  const WalletListScreen({
    super.key,
    required this.onCreateWallet,
    required this.onWalletSelected,
  });

  /// Called when the user taps the FAB to open [CreateWalletScreen].
  final VoidCallback onCreateWallet;

  /// Called when the user selects a wallet from the list.
  final void Function(Wallet wallet) onWalletSelected;

  @override
  State<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends State<WalletListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(const WalletListRequested());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Wallets')),
      floatingActionButton: Semantics(
        label: 'Create wallet',
        button: true,
        child: FloatingActionButton(
          onPressed: widget.onCreateWallet,
          child: const Icon(Icons.add),
        ),
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state.status == WalletStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Unknown error')),
            );
          }
        },
        builder: (context, state) {
          if (state.status == WalletStatus.loading) {
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
                onTap: () => widget.onWalletSelected(wallet),
              );
            },
          );
        },
      ),
    );
}
