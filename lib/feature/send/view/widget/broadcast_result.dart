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
    listener: (context, action) {
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
      final isSuccessful = regTestState.status == RegtestMiningStatus.successful;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Broadcasted',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green),
          ),
          const SizedBox(height: 8),
          if (txid case final t?)
            SelectableText(
              t,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          const SizedBox(height: 16),
          if (isSuccessful)
            Text(
              'Block mined!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green),
            )
          else
            ElevatedButton.icon(
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
        ],
      );
    },
  );
}
