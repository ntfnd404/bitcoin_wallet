import 'package:bitcoin_wallet/common/extensions/address_type_display.dart';
import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/core/routing/app_router.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_bloc.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_event.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_state.dart';
import 'package:bitcoin_wallet/feature/utxo/di/utxo_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// Displays unspent outputs (UTXOs) for a wallet.
///
/// Creates its own [UtxoBloc] via [UtxoScope] factory — each instance
/// owns an isolated UTXO BLoC with its own lifecycle.
/// Navigates to [UtxoDetailScreen] via [AppRouter].
class UtxoListScreen extends StatefulWidget {
  const UtxoListScreen({
    super.key,
    required this.wallet,
  });

  final Wallet wallet;

  @override
  State<UtxoListScreen> createState() => _UtxoListScreenState();
}

class _UtxoListScreenState extends State<UtxoListScreen> {
  late final UtxoBloc _utxoBloc;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _utxoBloc = UtxoScope.newUtxoBloc(context);
      _utxoBloc.add(UtxoListRequested(wallet: widget.wallet));
    }
  }

  @override
  void dispose() {
    _utxoBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<UtxoBloc>.value(
    value: _utxoBloc,
    child: Scaffold(
      appBar: AppBar(title: const Text('Unspent Outputs')),
      body: BlocConsumer<UtxoBloc, UtxoState>(
        listener: (context, state) {
          if (state.status == FetchStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Unknown error')),
            );
          }
        },
        builder: (context, state) {
          if (state.status == FetchStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.utxos.isEmpty) {
            return const Center(child: Text('No unspent outputs yet'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<UtxoBloc>().add(
                    UtxoRefreshRequested(wallet: widget.wallet),
                  );
            },
            child: ListView.builder(
              itemCount: state.utxos.length,
              itemBuilder: (context, index) {
                final utxo = state.utxos[index];

                return _UtxoTile(
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

class _UtxoTile extends StatelessWidget {
  const _UtxoTile({
    required this.utxo,
    required this.onTap,
  });

  final Utxo utxo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMempool = utxo.isMempool;
    final amountBtc = utxo.amountSat.btcDisplay;
    final addressLabel = utxo.address?.replaceRange(8, null, '...') ?? '(No address)';

    return Material(
      color: isMempool ? Colors.amber.shade50 : Colors.transparent,
      child: ListTile(
        onTap: onTap,
        title: Text(amountBtc),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              addressLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              '${utxo.type.shortLabel} • ${isMempool ? 'Unconfirmed' : utxo.confirmations}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
