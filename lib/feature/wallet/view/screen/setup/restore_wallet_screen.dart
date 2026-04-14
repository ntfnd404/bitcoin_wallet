import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/core/routing/app_router.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_bloc.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_event.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_state.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Allows the user to restore an HD wallet by entering an existing seed phrase.
///
/// Listens to [WalletBloc] and navigates to wallet detail screen
/// after successful restoration.
class RestoreWalletScreen extends StatefulWidget {
  const RestoreWalletScreen({super.key});

  @override
  State<RestoreWalletScreen> createState() => _RestoreWalletScreenState();
}

class _RestoreWalletScreenState extends State<RestoreWalletScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phraseController;
  List<String> _invalidWords = const [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phraseController = TextEditingController();
  }

  void _onPhraseChanged(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    final appDeps = AppScope.of(context);
    final invalid = text.trim().isEmpty
        ? <String>[]
        : words.where((w) => w.isNotEmpty && !appDeps.bip39Service.isValidWord(w)).toList();
    setState(() => _invalidWords = invalid);
  }

  void _onSubmit(BuildContext context) {
    final name = _nameController.text.trim();
    final words = _phraseController.text.trim().split(RegExp(r'\s+')).toList();
    context.read<WalletBloc>().add(
      WalletRestoreRequested(
        name: name,
        mnemonic: Mnemonic(words: words),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Restore Wallet')),
      body: BlocConsumer<WalletBloc, WalletState>(
        listenWhen: (previous, current) =>
            (current.status == WalletStatus.loaded && previous.status == WalletStatus.creating) ||
            current.status == WalletStatus.error,
        listener: (context, state) {
          if (state.status == WalletStatus.loaded) {
            final wallet = state.wallets.last;
            AppRouter.toWalletDetail(context, wallet);
          } else if (state.status == WalletStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Unknown error')),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state.status == WalletStatus.creating;
          final trimmed = _phraseController.text.trim();
          final words = trimmed.isEmpty ? <String>[] : trimmed.split(RegExp(r'\s+'));
          final wordCount = words.length;
          final isValidCount = wordCount == 12 || wordCount == 24;
          final canRestore =
              isValidCount && _invalidWords.isEmpty && _nameController.text.trim().isNotEmpty && !isSubmitting;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: 16),
                Semantics(
                  label: 'Seed phrase input',
                  child: TextField(
                    controller: _phraseController,
                    enabled: !isSubmitting,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Seed phrase (12 or 24 words)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    onChanged: _onPhraseChanged,
                  ),
                ),
                if (trimmed.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _WordHighlight(words: words, invalidWords: _invalidWords),
                ],
                const SizedBox(height: 8),
                if (!isValidCount && trimmed.isNotEmpty)
                  Text(
                    'Enter 12 or 24 words (current: $wordCount)',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Restore wallet button',
                  button: true,
                  child: ElevatedButton(
                    onPressed: canRestore ? () => _onSubmit(context) : null,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Restore'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
}

/// Renders the phrase with invalid words highlighted in red.
class _WordHighlight extends StatelessWidget {
  const _WordHighlight({required this.words, required this.invalidWords});

  final List<String> words;
  final List<String> invalidWords;

  @override
  Widget build(BuildContext context) {
    final spans = words
        .map(
          (word) => TextSpan(
            text: '$word ',
            style: TextStyle(
              color: invalidWords.contains(word) ? Theme.of(context).colorScheme.error : null,
            ),
          ),
        )
        .toList();

    return Text.rich(TextSpan(children: spans));
  }
}
