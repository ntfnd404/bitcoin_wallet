import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/core/routing/app_router.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_action.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_bloc.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_event.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_state.dart';
import 'package:bitcoin_wallet/feature/utxo/di/utxo_scope.dart';
import 'package:bitcoin_wallet/feature/utxo/view/widget/utxo_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/wallet.dart';

/// Displays unspent outputs (UTXOs) for a wallet.
///
/// Creates its own [UtxoBloc] via [UtxoScope] factory — lifecycle managed
/// by [BlocProvider].
class UtxoListScreen extends StatelessWidget {
  const UtxoListScreen({super.key, required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) => BlocProvider<UtxoBloc>(
    create: (ctx) => UtxoScope.newUtxoBloc(ctx)..add(UtxoListRequested(wallet: wallet)),
    child: Scaffold(
      appBar: AppBar(title: const Text('Unspent Outputs')),
      body: ActionBlocConsumer<UtxoBloc, UtxoState, UtxoAction>(
        listener: (context, action) {
          switch (action) {
            case UtxoErrorOccurredAction(:final exception):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(exception.toString())),
              );
          }
        },
        builder: (context, state) {
          if (state.status == FetchStatus.processing) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.utxos.isEmpty) {
            return const Center(child: Text('No unspent outputs yet'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<UtxoBloc>().add(
                UtxoRefreshRequested(wallet: wallet),
              );
            },
            child: ListView.builder(
              itemCount: state.utxos.length,
              itemBuilder: (context, index) {
                final utxo = state.utxos[index];

                return UtxoTile(
                  utxo: utxo,
                  onTap: () => AppRouter.toUtxoDetail(context, utxo),
                );
              },
            ),
          );
        },
      ),
    ),
  );
}
