import 'package:bitcoin_wallet/common/extensions/address_type_display.dart';
import 'package:flutter/material.dart';
import 'package:transaction/transaction.dart';

/// Selectable UTXO row for the UTXO picker screen.
class UtxoPickerTile extends StatelessWidget {
  const UtxoPickerTile({
    super.key,
    required this.utxo,
    required this.isSelected,
    required this.onToggle,
  });

  final Utxo utxo;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isMempool = utxo.isMempool;
    final amountBtc = utxo.amountSat.btcDisplay;
    final addressLabel = utxo.address?.replaceRange(8, null, '...') ?? '(No address)';
    final confirmLabel = isMempool ? 'Unconfirmed' : '${utxo.confirmations} conf';

    return Semantics(
      label:
          'UTXO $amountBtc BTC $addressLabel, $confirmLabel,'
          ' ${isSelected ? "selected" : "not selected"}',
      child: Material(
        color: isMempool ? Colors.amber.withValues(alpha: 0.1) : Colors.transparent,
        child: CheckboxListTile(
          value: isSelected,
          onChanged: (_) => onToggle(),
          title: Text(
            '$amountBtc BTC',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '$addressLabel · ${utxo.type.shortLabel} · $confirmLabel',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
