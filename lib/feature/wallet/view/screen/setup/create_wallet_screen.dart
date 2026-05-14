import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/core/routing/app_router.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_action.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_bloc.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_event.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  bool _isHd = false;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  void _onSubmit(BuildContext context) {
    final name = _nameController.text.trim();
    final bloc = context.read<WalletBloc>();
    if (_isHd) {
      bloc.add(HdWalletCreateRequested(name: name));
    } else {
      bloc.add(NodeWalletCreateRequested(name: name));
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
    body: ActionBlocConsumer<WalletBloc, WalletState, WalletAction>(
      listener: (context, action) {
        switch (action) {
          case WalletNodeCreated(:final wallet):
            AppRouter.toWalletDetail(context, wallet);
          case WalletHdAwaitingConfirmation(:final wallet, :final mnemonic):
            AppRouter.toSeedPhrase(context, mnemonic, wallet.id);
          case WalletHdConfirmed():
            Navigator.pop(context);
          case WalletErrorOccurred(:final exception):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(exception.toString())),
            );
          case _:
            break;
        }
      },
      builder: (context, state) {
        final isSubmitting = state.status == WalletStatus.processing;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AbsorbPointer(
                absorbing: isSubmitting,
                child: RadioGroup<bool>(
                  groupValue: _isHd,
                  onChanged: (value) => setState(() => _isHd = value ?? _isHd),
                  child: const Column(
                    children: [
                      RadioListTile<bool>(
                        title: Text('Node Wallet'),
                        subtitle: Text('Custodial — keys managed by Bitcoin Core'),
                        value: false,
                      ),
                      RadioListTile<bool>(
                        title: Text('HD Wallet'),
                        subtitle: Text('Non-custodial — you own the seed phrase'),
                        value: true,
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
                  onPressed: isSubmitting || _nameController.text.trim().isEmpty ? null : () => _onSubmit(context),
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
