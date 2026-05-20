import 'package:flutter/material.dart';
import 'package:transaction/transaction.dart';

class TransactionOutputTile extends StatelessWidget {
  const TransactionOutputTile({super.key, required this.output, required this.textTheme});

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
