import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_action.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_bloc.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_event.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_state.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/wallet.dart';

/// Dev-only tile that mines one block via [RegtestMiningBloc].
///
/// Must be placed inside a [RegtestMiningScope]. Dispatches
/// [MineBlockWithWallet] — the BLoC resolves the target address internally.
class MineBlockTile extends StatelessWidget {
  const MineBlockTile({super.key, required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) => ActionBlocConsumer<RegtestMiningBloc, RegtestMiningState, RegtestMiningAction>(
    actionListener: (context, _, action) {
      switch (action) {
        case RegtestMiningFailedAction(:final exception):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mining failed: ${exception.toString()}')),
          );
        case RegtestMiningUnexpectedFailedAction():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mining failed: unexpected error')),
          );
      }
    },
    builder: (context, state) {
      final isProcessing = state.status == RegtestMiningStatus.processing;

      return ListTile(
        title: Text(
          state.status == RegtestMiningStatus.successful ? 'Block mined!' : 'Mine 1 block (dev)',
        ),
        leading: isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.construction_outlined),
        onTap: isProcessing
            ? null
            : () => context.read<RegtestMiningBloc>().add(
                MineBlockWithWallet(wallet: wallet),
              ),
      );
    },
  );
}
