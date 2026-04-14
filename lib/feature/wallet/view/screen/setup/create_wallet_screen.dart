import 'package:bitcoin_wallet/core/routing/app_router.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_bloc.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_event.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_state.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Allows the user to choose a wallet type and enter a wallet name.
///
/// Listens to [WalletBloc] and navigates to the appropriate next screen
/// (wallet detail for Node wallets, seed phrase confirmation for HD wallets).
class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  WalletType _selectedType = WalletType.node;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  void _onSubmit(BuildContext context) {
    final name = _nameController.text.trim();
    final bloc = context.read<WalletBloc>();
    if (_selectedType == WalletType.node) {
      bloc.add(NodeWalletCreateRequested(name: name));
    } else {
      bloc.add(HdWalletCreateRequested(name: name));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Create Wallet')),
      body: BlocConsumer<WalletBloc, WalletState>(
        listenWhen: (previous, current) =>
            (current.status == WalletStatus.loaded && previous.status == WalletStatus.creating) ||
            current.status == WalletStatus.awaitingSeedConfirmation ||
            current.status == WalletStatus.error,
        listener: (context, state) {
          if (state.status == WalletStatus.loaded) {
            final wallet = state.pendingWallet;
            if (wallet != null) {
              AppRouter.toWalletDetail(context, wallet);
            }
          } else if (state.status == WalletStatus.awaitingSeedConfirmation) {
            // Seed phrase screen is pushed by WalletDetailScreen via BlocListener
            // For now, just pop to let the navigation flow naturally
            Navigator.pop(context);
          } else if (state.status == WalletStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Unknown error')),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state.status == WalletStatus.creating;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AbsorbPointer(
                  absorbing: isSubmitting,
                  child: RadioGroup<WalletType>(
                    groupValue: _selectedType,
                    onChanged: (value) => setState(() => _selectedType = value ?? _selectedType),
                    child: const Column(
                      children: [
                        RadioListTile<WalletType>(
                          title: Text('Node Wallet'),
                          subtitle: Text('Custodial — keys managed by Bitcoin Core'),
                          value: WalletType.node,
                        ),
                        RadioListTile<WalletType>(
                          title: Text('HD Wallet'),
                          subtitle: Text('Non-custodial — you own the seed phrase'),
                          value: WalletType.hd,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Wallet name input',
                  child: TextField(
                    controller: _nameController,
                    enabled: !isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Wallet name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(
                  label: 'Create wallet button',
                  button: true,
                  child: ElevatedButton(
                    onPressed: isSubmitting || _nameController.text.trim().isEmpty
                        ? null
                        : () => _onSubmit(context),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
}
