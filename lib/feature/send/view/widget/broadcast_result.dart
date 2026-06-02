import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_action.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_bloc.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_event.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_state.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BroadcastResult extends StatelessWidget {
  const BroadcastResult({
    super.key,
    required this.txid,
    required this.changeAddress,
  });

  final String? txid;
  final String changeAddress;

  @override
  Widget build(BuildContext context) => ActionBlocConsumer<RegtestMiningBloc, RegtestMiningState, RegtestMiningAction>(
    actionListener: (context, _, action) {
      switch (action) {
        case RegtestMiningFailedAction(:final exception):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(exception.toString())),
          );
        case RegtestMiningUnexpectedFailedAction():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mining failed: unexpected error')),
          );
      }
    },
    builder: (context, regTestState) {
      final isProcessing = regTestState.status == RegtestMiningStatus.processing;
      final isConfirmed = regTestState.status == RegtestMiningStatus.successful;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1 — Broadcast
          const _StepTile(
            number: 1,
            title: 'Broadcasted to mempool',
            subtitle: 'The transaction is signed and sent to the Bitcoin node. '
                'It is unconfirmed until included in a block.',
            status: _StepStatus.done,
          ),
          if (txid case final t?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 0, 12),
              child: SelectableText(
                t,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            )
          else
            const SizedBox(height: 12),

          // Step 2 — Confirm
          _StepTile(
            number: 2,
            title: isConfirmed ? 'Confirmed — block mined!' : 'Mine a block to confirm',
            subtitle: isConfirmed
                ? 'The transaction now has 1 confirmation. '
                    'It will appear in your transaction history.'
                : 'In regtest there are no real miners. '
                    'Mine 1 block manually to include this transaction in the blockchain.',
            status: isConfirmed
                ? _StepStatus.done
                : isProcessing
                    ? _StepStatus.inProgress
                    : _StepStatus.pending,
          ),
          if (!isConfirmed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
              child: ElevatedButton.icon(
                onPressed: isProcessing || changeAddress.isEmpty
                    ? null
                    : () => context.read<RegtestMiningBloc>().add(
                        MineBlockRequested(toAddress: changeAddress),
                      ),
                icon: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.settings_outlined),
                label: Text(isProcessing ? 'Mining…' : 'Mine 1 block'),
              ),
            ),
        ],
      );
    },
  );
}

enum _StepStatus { pending, inProgress, done }

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final int number;
  final String title;
  final String subtitle;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (status) {
      _StepStatus.done => (Icons.check_circle, Colors.green),
      _StepStatus.inProgress => (Icons.hourglass_top, Colors.orange),
      _StepStatus.pending => (Icons.radio_button_unchecked, Colors.grey),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step $number — $title',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: status == _StepStatus.pending ? Colors.grey : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
