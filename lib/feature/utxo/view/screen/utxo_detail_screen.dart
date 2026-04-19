import 'package:bitcoin_wallet/common/extensions/address_type_display.dart';
import 'package:bitcoin_wallet/common/widgets/detail_section.dart';
import 'package:flutter/material.dart';
import 'package:transaction/transaction.dart';

/// Displays details of a single UTXO.
///
/// Stateless — all data passed in constructor.
/// Shows: txid, vout, amount, confirmations, address, scriptPubKey (hex), type, spendable.
class UtxoDetailScreen extends StatelessWidget {
  const UtxoDetailScreen({
    super.key,
    required this.utxo,
  });

  final Utxo utxo;

  @override
  Widget build(BuildContext context) {
    final amountBtc = utxo.amountSat.btcDisplay;

    return Scaffold(
      appBar: AppBar(title: const Text('UTXO Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DetailSection(
            title: 'TXID',
            child: CopyableText(text: utxo.txid),
          ),
          const SizedBox(height: 16),
          DetailSection(
            title: 'VOUT',
            child: Text(utxo.vout.toString()),
          ),
          const SizedBox(height: 16),
          DetailSection(
            title: 'Amount',
            child: Text('$amountBtc BTC'),
          ),
          const SizedBox(height: 16),
          DetailSection(
            title: 'Confirmations',
            child: Text(
              utxo.isMempool ? 'Unconfirmed (0)' : '${utxo.confirmations}',
            ),
          ),
          if (utxo.address != null) ...[
            const SizedBox(height: 16),
            DetailSection(
              title: 'Address',
              child: CopyableText(text: utxo.address!),
            ),
          ],
          const SizedBox(height: 16),
          DetailSection(
            title: 'Script PubKey (hex)',
            child: CopyableText(text: utxo.scriptPubKey),
          ),
          const SizedBox(height: 16),
          DetailSection(
            title: 'Type',
            child: Text(utxo.type.fullLabel),
          ),
          const SizedBox(height: 16),
          DetailSection(
            title: 'Spendable',
            child: Text(utxo.spendable ? 'Yes' : 'No'),
          ),
          if (utxo.derivationPath != null) ...[
            const SizedBox(height: 16),
            DetailSection(
              title: 'Derivation Path',
              child: Text(utxo.derivationPath!),
            ),
          ],
        ],
      ),
    );
  }
}
