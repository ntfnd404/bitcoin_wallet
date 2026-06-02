import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/core/routing/app_router.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_action.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_bloc.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_event.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_filter.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_state.dart';
import 'package:bitcoin_wallet/feature/transaction/list/di/transaction_list_scope.dart';
import 'package:bitcoin_wallet/feature/transaction/list/view/widget/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// Displays transaction history for a wallet with All / Incoming / Outgoing filter
/// and sticky date-group headers.
class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key, required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) => BlocProvider<TransactionBloc>(
    create: (ctx) => TransactionListScope.newTransactionBloc(ctx)
      ..add(TransactionListRequested(wallet: wallet)),
    child: Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: ActionBlocConsumer<TransactionBloc, TransactionState, TransactionAction>(
        actionListener: (context, _, action) {
          switch (action) {
            case TransactionErrorOccurredAction(:final exception):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(exception.toString())),
              );
          }
        },
        builder: (context, state) {
          if (state.status == FetchStatus.processing && state.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = state.filtered;
          final groups = _groupByDate(filtered);

          return Column(
            children: [
              _FilterBar(current: state.filter),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          state.transactions.isEmpty
                              ? 'No transactions yet'
                              : 'No ${state.filter.label.toLowerCase()} transactions',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => context
                            .read<TransactionBloc>()
                            .add(TransactionRefreshRequested(wallet: wallet)),
                        child: CustomScrollView(
                          slivers: [
                            for (final group in groups) ...[
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _DateHeaderDelegate(
                                  label: group.label,
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                ),
                              ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final tx = group.items[index];

                                    return TransactionTile(
                                      transaction: tx,
                                      onTap: () => AppRouter.toTransactionDetail(
                                        context,
                                        tx,
                                        wallet,
                                      ),
                                    );
                                  },
                                  childCount: group.items.length,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

// ── Date grouping ────────────────────────────────────────────────────────────

typedef _Group = ({String label, List<Transaction> items});

List<_Group> _groupByDate(List<Transaction> txs) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final Map<String, List<Transaction>> buckets = {};
  final List<String> order = [];

  for (final tx in txs) {
    final d = tx.timestamp;
    final day = DateTime(d.year, d.month, d.day);
    final String label;

    if (day == today) {
      label = 'Today';
    } else if (day == yesterday) {
      label = 'Yesterday';
    } else if (d.year == now.year) {
      label = '${_month(d.month)} ${d.day}';
    } else {
      label = '${_month(d.month)} ${d.day}, ${d.year}';
    }

    if (!buckets.containsKey(label)) {
      buckets[label] = [];
      order.add(label);
    }
    buckets[label]!.add(tx);
  }

  return order.map((label) => (label: label, items: buckets[label]!)).toList();
}

const _months = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _month(int m) => _months[m];

// ── Sticky header delegate ───────────────────────────────────────────────────

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;
  final Color backgroundColor;

  static const double _height = 40;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  const _DateHeaderDelegate({
    required this.label,
    required this.backgroundColor,
  });

  @override
  bool shouldRebuild(_DateHeaderDelegate old) =>
      label != old.label || backgroundColor != old.backgroundColor;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    color: backgroundColor,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _DateChip(label: label),
      ),
    ),
  );
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current});

  final TransactionFilter current;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: SegmentedButton<TransactionFilter>(
      segments: TransactionFilter.values
          .map(
            (f) => ButtonSegment(
              value: f,
              label: Text(f.label),
              icon: switch (f) {
                TransactionFilter.all => const Icon(Icons.list),
                TransactionFilter.incoming => const Icon(Icons.arrow_downward),
                TransactionFilter.outgoing => const Icon(Icons.arrow_upward),
              },
            ),
          )
          .toList(),
      selected: {current},
      onSelectionChanged: (selection) => context
          .read<TransactionBloc>()
          .add(TransactionFilterChanged(filter: selection.first)),
    ),
  );
}
