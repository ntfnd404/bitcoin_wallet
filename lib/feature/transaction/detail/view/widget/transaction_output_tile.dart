import 'package:bitcoin_wallet/feature/transaction/detail/bloc/decoded_transaction_output.dart';
import 'package:flutter/material.dart';

class TransactionOutputTile extends StatelessWidget {
  const TransactionOutputTile({
    super.key,
    required this.decoded,
    required this.textTheme,
  });

  final DecodedTransactionOutput decoded;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final output = decoded.output;
    final amountBtc = output.amountSat.btcDisplay;
    final addressLabel = output.address ?? '(no address)';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: 2),
          Text(
            decoded.scriptTypeLabel,
            style: textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
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
