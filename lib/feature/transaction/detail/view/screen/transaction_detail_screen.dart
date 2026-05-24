import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/common/widgets/copyable_text.dart';
import 'package:bitcoin_wallet/common/widgets/detail_section.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_action.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_bloc.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_event.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_state.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/di/transaction_detail_scope.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/view/widget/transaction_detail_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// Displays full detail of a single transaction.
///
/// Shows basic info from [transaction] immediately, then fetches decoded
/// inputs, outputs, size, weight, and raw hex via [TransactionDetailBloc].
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.wallet,
  });

  final Transaction transaction;
  final Wallet wallet;

  @override
  Widget build(BuildContext context) => BlocProvider<TransactionDetailBloc>(
    create: (ctx) => TransactionDetailScope.newTransactionDetailBloc(ctx)
      ..add(
        TransactionDetailRequested(
          txid: transaction.txid,
          walletName: wallet.name,
        ),
      ),
    child: Scaffold(
      appBar: AppBar(title: const Text('Transaction Detail')),
      body: ActionBlocConsumer<TransactionDetailBloc, TransactionDetailState, TransactionDetailAction>(
        actionListener: (context, _, action) {
          switch (action) {
            case TransactionDetailErrorOccurredAction(:final exception):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(exception.toString())),
              );
            case TransactionDetailUnexpectedFailedAction():
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('An unexpected error occurred.')),
              );
          }
        },
        builder: (context, state) {
          final tx = transaction;
          final amountBtc = tx.amountSat.btcDisplay;
          final feeBtc = tx.feeSat?.btcDisplay;
          final isIncoming = tx.direction == TransactionDirection.incoming;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Basic info (always available) ────────────────────────
              DetailSection(
                title: 'TXID',
                child: CopyableText(text: tx.txid),
              ),
              const SizedBox(height: 16),
              DetailSection(
                title: 'Direction',
                child: Text(isIncoming ? 'Incoming' : 'Outgoing'),
              ),
              const SizedBox(height: 16),
              DetailSection(
                title: 'Amount',
                child: Text('$amountBtc BTC'),
              ),
              if (feeBtc != null) ...[
                const SizedBox(height: 16),
                DetailSection(
                  title: 'Fee',
                  child: Text('$feeBtc BTC'),
                ),
              ],
              const SizedBox(height: 16),
              DetailSection(
                title: 'Status',
                child: Text(
                  tx.isMempool
                      ? 'Unconfirmed (in mempool)'
                      : 'Confirmed (${tx.confirmations} block${tx.confirmations == 1 ? '' : 's'})',
                ),
              ),
              const SizedBox(height: 16),
              DetailSection(
                title: 'Time',
                child: Text(
                  tx.timestamp.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              // ── Decoded detail (loaded on demand) ────────────────────
              if (state.status == FetchStatus.processing) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],

              if (state.status == FetchStatus.idle && state.detail != null)
                TransactionDetailBody(
                  detail: state.detail!,
                  decodedOutputs: state.decodedOutputs,
                  decodedInputs: state.decodedInputs,
                ),
            ],
          );
        },
      ),
    ),
  );
}
