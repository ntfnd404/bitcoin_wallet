import 'package:bitcoin_wallet/common/extensions/address_type_display.dart';
import 'package:flutter/material.dart';
import 'package:transaction/transaction.dart';

class UtxoTile extends StatelessWidget {
  const UtxoTile({
    super.key,
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
            Text(addressLabel, style: Theme.of(context).textTheme.bodySmall),
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
