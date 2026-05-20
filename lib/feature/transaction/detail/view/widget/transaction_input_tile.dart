import 'package:flutter/material.dart';
import 'package:transaction/transaction.dart';

class TransactionInputTile extends StatelessWidget {
  const TransactionInputTile({super.key, required this.input, required this.textTheme});

  final TransactionInput input;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final label = input.isCoinbase ? 'Coinbase' : '${input.prevTxid!.substring(0, 8)}…:${input.prevVout}';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}
