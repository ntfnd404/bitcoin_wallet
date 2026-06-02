import 'package:flutter/material.dart';
import 'package:transaction/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
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

    final address = transaction.address;
    final addressShort = address != null && address.length > 20
        ? '${address.substring(0, 10)}…${address.substring(address.length - 8)}'
        : address;
    final statusLabel = isMempool ? 'Unconfirmed' : 'Confirmed ($confirmations)';
    final subtitleText = addressShort != null ? '$statusLabel · $addressShort' : statusLabel;

    return Material(
      color: isMempool ? Colors.amber.shade50 : Colors.transparent,
      child: ListTile(
        onTap: onTap,
        title: Text(amountBtc),
        subtitle: Text(subtitleText, style: Theme.of(context).textTheme.bodySmall),
        leading: Icon(
          isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
          color: isIncoming ? Colors.green : Colors.red,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
