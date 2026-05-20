import 'package:bitcoin_wallet/common/widgets/copyable_text.dart';
import 'package:bitcoin_wallet/common/widgets/detail_section.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_state.dart';
import 'package:flutter/material.dart';

class SigningBroadcastResult extends StatelessWidget {
  const SigningBroadcastResult({super.key, required this.state});

  final SigningState state;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Broadcasted',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green),
      ),
      const SizedBox(height: 12),
      DetailSection(
        title: 'TXID',
        child: CopyableText(text: state.txid ?? ''),
      ),
      if (state.broadcastedTx case final tx?) ...[
        const SizedBox(height: 12),
        DetailSection(
          title: 'Confirmations',
          child: Text('${tx.confirmations}'),
        ),
      ],
    ],
  );
}
