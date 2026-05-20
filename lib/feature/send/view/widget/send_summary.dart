import 'package:bitcoin_wallet/feature/send/bloc/coin_selection_mode.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_bloc.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_event.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_state.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_status.dart';
import 'package:bitcoin_wallet/feature/send/view/widget/summary_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/wallet.dart';

class SendSummary extends StatelessWidget {
  const SendSummary({super.key, required this.state, required this.wallet});

  final SendState state;
  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final strategy = state.selectedStrategy;
    final result = strategy == null
        ? null
        : state.strategies
            ?.where((e) => e.name == strategy)
            .firstOrNull
            ?.result;
    final isSending = state.status == SendStatus.sending;

    if (result == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          state.selectionMode == CoinSelectionMode.auto
              ? 'Summary — Auto: $strategy'
              : 'Summary — Manual: $strategy',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SummaryRow(label: 'Inputs', value: '${result.inputs.length}'),
        SummaryRow(label: 'To recipient', value: '${state.amountSat} sat'),
        SummaryRow(
          label: 'Change',
          value: result.changeSat.value > 0
              ? '${result.changeSat.value} sat'
              : '(none — absorbed into fee)',
        ),
        SummaryRow(label: 'Fee', value: '${result.feeSat.value} sat'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: isSending ? null : () => context.read<SendBloc>().add(const SendConfirmed()),
          icon: isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(isSending ? 'Sending…' : 'Confirm & Send'),
        ),
      ],
    );
  }
}
