import 'package:bitcoin_wallet/feature/address/bloc/address_bloc.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_event.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_state.dart';
import 'package:bitcoin_wallet/feature/address/view/widget/address_type_section.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_bloc.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_event.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_state.dart';
import 'package:bitcoin_wallet/feature/wallet/view/screen/setup/seed_phrase_screen.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows addresses for a single wallet grouped by [AddressType].
///
/// Provides address management and seed phrase viewing for HD wallets.
class WalletDetailScreen extends StatefulWidget {
  const WalletDetailScreen({
    super.key,
    required this.wallet,
    required this.onAddressSelected,
  });

  final Wallet wallet;

  /// Called when the user taps an address row.
  final void Function(Address address) onAddressSelected;

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AddressBloc>().add(AddressListRequested(wallet: widget.wallet));
  }

  void _navigateToSeedPhrase(BuildContext context, Mnemonic mnemonic) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/wallet/seed'),
        builder: (_) => SeedPhraseScreen(
          mnemonic: mnemonic,
          walletId: widget.wallet.id,
          onConfirmed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
              _navigateToSeedPhrase(context, mnemonic);
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
              children: AddressType.values.map((type) {
                final filtered = state.addresses.where((a) => a.type == type).toList();

                return AddressTypeSection(
                  type: type,
                  addresses: filtered,
                  isGenerating: isGenerating,
                  onGenerate: () => context.read<AddressBloc>().add(
                    AddressGenerateRequested(wallet: widget.wallet, type: type),
                  ),
                  onAddressSelected: widget.onAddressSelected,
                );
              }).toList(),
            );
          },
        ),
      ),
    );
}
