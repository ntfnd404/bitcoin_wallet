import 'package:flutter/material.dart';
import 'package:transaction/transaction.dart';

class UtxoTile extends StatelessWidget {
  const UtxoTile(this.utxo, {super.key});

  final ScannedUtxo utxo;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: ListTile(
      title: Text(
        '${utxo.txid.substring(0, 12)}…:${utxo.vout}',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
      subtitle: utxo.address != null
          ? Text(
              utxo.address ?? '',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Text(
        '${utxo.amountSat.value} sat',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  );
}
