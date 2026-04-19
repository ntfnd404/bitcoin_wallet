import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/common/widgets/detail_section.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_bloc.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_event.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_state.dart';
import 'package:bitcoin_wallet/feature/transaction/di/transaction_scope.dart';
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
        create: (ctx) => TransactionScope.newTransactionDetailBloc(ctx)
          ..add(TransactionDetailRequested(
            txid: transaction.txid,
            walletName: wallet.name,
          )),
        child: Scaffold(
          appBar: AppBar(title: const Text('Transaction Detail')),
          body: BlocConsumer<TransactionDetailBloc, TransactionDetailState>(
            listener: (context, state) {
              if (state.status == FetchStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'Unknown error'),
                  ),
                );
              }
            },
            builder: (context, state) {
              final tx = transaction;
              final amountBtc = tx.amountSat.btcDisplay;
              final feeBtc = tx.feeSat?.btcDisplay;
              final isIncoming =
                  tx.direction == TransactionDirection.incoming;

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
                  if (state.status == FetchStatus.loading) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],

                  if (state.status == FetchStatus.loaded &&
                      state.detail != null)
                    _DetailBody(detail: state.detail!),
                ],
              );
            },
          ),
        ),
      );
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final TransactionDetail detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        DetailSection(
          title: 'Size',
          child: Text('${detail.size} bytes'),
        ),
        const SizedBox(height: 16),
        DetailSection(
          title: 'Weight',
          child: Text('${detail.weight} WU'),
        ),
        const SizedBox(height: 16),
        DetailSection(
          title: 'Inputs (${detail.inputs.length})',
          child: Column(
            children: [
              for (final input in detail.inputs)
                _InputTile(input: input, textTheme: textTheme),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DetailSection(
          title: 'Outputs (${detail.outputs.length})',
          child: Column(
            children: [
              for (final output in detail.outputs)
                _OutputTile(output: output, textTheme: textTheme),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DetailSection(
          title: 'Raw Hex',
          child: CopyableText(text: detail.hex),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _InputTile extends StatelessWidget {
  const _InputTile({required this.input, required this.textTheme});

  final TransactionInput input;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final label = input.isCoinbase
        ? 'Coinbase'
        : '${input.prevTxid!.substring(0, 8)}…:${input.prevVout}';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}

class _OutputTile extends StatelessWidget {
  const _OutputTile({required this.output, required this.textTheme});

  final TransactionOutput output;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final amountBtc = output.amountSat.btcDisplay;
    final addressLabel = output.address ?? '(no address)';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              addressLabel,
              style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text('$amountBtc BTC', style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
