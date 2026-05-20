import 'package:bitcoin_wallet/feature/transaction/detail/bloc/decoded_transaction_input.dart';
import 'package:flutter/material.dart';

class TransactionInputTile extends StatelessWidget {
  const TransactionInputTile({
    super.key,
    required this.decoded,
    required this.textTheme,
  });

  final DecodedTransactionInput decoded;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final input = decoded.input;
    final label = input.isCoinbase
        ? 'Coinbase'
        : '${input.prevTxid!.substring(0, 8)}…:${input.prevVout}';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
          if (decoded.asm.isNotEmpty)
            Text(
              decoded.asm,
              style: textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              softWrap: true,
            ),
        ],
      ),
    );
  }
}
