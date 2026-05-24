import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/core/routing/app_router.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_picker/utxo_picker_action.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_picker/utxo_picker_bloc.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_picker/utxo_picker_event.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_picker/utxo_picker_state.dart';
import 'package:bitcoin_wallet/feature/utxo/di/utxo_picker_scope.dart';
import 'package:bitcoin_wallet/feature/utxo/view/widget/utxo_picker_tile.dart';
import 'package:bitcoin_wallet/feature/utxo/view/widget/utxo_picker_total_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/wallet.dart';

/// Allows the developer to select specific UTXOs before the send form.
///
/// The [UtxoPickerBloc] lives above this screen in the route stack, so
/// selection is preserved across back-navigation from [SendScreen].
class UtxoPickerScreen extends StatelessWidget {
  const UtxoPickerScreen({super.key, required this.wallet});

  final NodeWallet wallet;

  @override
  Widget build(BuildContext context) => BlocProvider<UtxoPickerBloc>(
    create: (_) => UtxoPickerScope.newBloc(context)..add(UtxoPickerLoaded(walletName: wallet.name)),
    child: Scaffold(
      appBar: AppBar(title: const Text('Select UTXOs')),
      body: ActionBlocConsumer<UtxoPickerBloc, UtxoPickerState, UtxoPickerAction>(
        actionListener: (context, _, action) {
          switch (action) {
            case UtxoPickerLoadFailedAction(:final exception):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(exception.toString())),
              );
            case UtxoPickerUnexpectedFailedAction():
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to load UTXOs.')),
              );
          }
        },
        builder: (context, state) {
          if (state.utxos.isEmpty && state.status == FetchStatus.idle) {
            return const Center(child: Text('No spendable UTXOs'));
          }

          if (state.status == FetchStatus.processing) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: state.utxos.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final utxo = state.utxos[index];
                    final key = '${utxo.txid}:${utxo.vout}';

                    return UtxoPickerTile(
                      utxo: utxo,
                      isSelected: state.selectedKeys.contains(key),
                      onToggle: () => context.read<UtxoPickerBloc>().add(
                        UtxoPickerSelectionToggled(
                          txid: utxo.txid,
                          vout: utxo.vout,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              UtxoPickerTotalRow(
                inputSumSat: state.inputSumSat,
                estimatedFeeSat: state.estimatedFeeSat,
                estimatedChangeSat: state.estimatedChangeSat,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: state.canProceed
                      ? () => AppRouter.toSendWithPinnedInputs(
                          context,
                          wallet,
                          state.selectedUtxos,
                        )
                      : null,
                  child: const Text('Next'),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
