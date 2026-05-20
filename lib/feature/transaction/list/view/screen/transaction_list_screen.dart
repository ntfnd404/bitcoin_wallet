import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/core/routing/app_router.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_action.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_bloc.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_event.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_state.dart';
import 'package:bitcoin_wallet/feature/transaction/list/di/transaction_list_scope.dart';
import 'package:bitcoin_wallet/feature/transaction/list/view/widget/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      body: ActionBlocConsumer<TransactionBloc, TransactionState, TransactionAction>(
        listener: (context, action) {
          switch (action) {
            case TransactionErrorOccurredAction(:final exception):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(exception.toString())),
              );
          }
        },
        builder: (context, state) {
          if (state.status == FetchStatus.processing) {
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

                return TransactionTile(
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
