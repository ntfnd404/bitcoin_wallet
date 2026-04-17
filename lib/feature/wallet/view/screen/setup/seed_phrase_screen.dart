import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_bloc.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_event.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_state.dart';
import 'package:bitcoin_wallet/feature/wallet/view/widget/seed_word_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keys/keys.dart';

/// Shows the generated mnemonic and requires the user to confirm they saved it.
class SeedPhraseScreen extends StatefulWidget {
  const SeedPhraseScreen({
    super.key,
    required this.mnemonic,
    required this.walletId,
    required this.onConfirmed,
  });

  /// Mnemonic to display. Passed explicitly — never read from BLoC state at build time.
  final Mnemonic mnemonic;

  /// The pending wallet id used in [SeedConfirmed].
  final String walletId;

  /// Called after [SeedConfirmed] is dispatched and BLoC emits [loaded].
  final VoidCallback onConfirmed;

  @override
  State<SeedPhraseScreen> createState() => _SeedPhraseScreenState();
}

class _SeedPhraseScreenState extends State<SeedPhraseScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Seed Phrase')),
      body: BlocListener<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state.status == WalletStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Unknown error')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Write down your seed phrase. Anyone who sees it can access your funds.',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: widget.mnemonic.words.length,
                  itemBuilder: (context, index) => SeedWordTile(
                    index: index + 1,
                    word: widget.mnemonic.words[index],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'I have saved my seed phrase confirmation',
                child: CheckboxListTile(
                  value: _confirmed,
                  onChanged: (value) => setState(() => _confirmed = value ?? false),
                  title: const Text('I have saved my seed phrase'),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                label: 'Continue button',
                button: true,
                child: ElevatedButton(
                  onPressed: _confirmed
                      ? () {
                          context.read<WalletBloc>().add(SeedConfirmed(walletId: widget.walletId));
                          widget.onConfirmed();
                        }
                      : null,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
