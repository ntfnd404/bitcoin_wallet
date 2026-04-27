import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/core/routing/app_router.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_bloc.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_event.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_state.dart';
import 'package:bitcoin_wallet/feature/transaction/list/di/transaction_list_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// Displays transaction history for a wallet.
///
/// Creates its own [TransactionBloc] via [TransactionListScope] — lifecycle is
/// managed automatically by [BlocProvider].
/// Navigates to [TransactionDetailScreen] via [AppRouter].
class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key, required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) => BlocProvider<TransactionBloc>(
    create: (ctx) => TransactionListScope.newTransactionBloc(ctx)..add(TransactionListRequested(wallet: wallet)),
    child: Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: BlocConsumer<TransactionBloc, TransactionState>(
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
          if (state.status == FetchStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.transactions.isEmpty) {
            return const Center(child: Text('No transactions yet'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TransactionBloc>().add(TransactionRefreshRequested(wallet: wallet));
            },
            child: ListView.builder(
              itemCount: state.transactions.length,
              itemBuilder: (context, index) {
                final tx = state.transactions[index];

                return _TransactionTile(
                  transaction: tx,
                  onTap: () => AppRouter.toTransactionDetail(context, tx, wallet),
                );
              },
            ),
          );
        },
      ),
    ),
  );
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onTap,
  });

  final Transaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMempool = transaction.isMempool;
    final isIncoming = transaction.direction == TransactionDirection.incoming;
    final amountBtc = transaction.amountSat.btcDisplay;
    final confirmations = transaction.confirmations;

    return Material(
      color: isMempool ? Colors.amber.shade50 : Colors.transparent,
      child: ListTile(
        onTap: onTap,
        title: Text(amountBtc),
        subtitle: Text(
          isMempool ? 'Unconfirmed' : 'Confirmed ($confirmations)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        leading: Icon(
          isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
          color: isIncoming ? Colors.green : Colors.red,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
