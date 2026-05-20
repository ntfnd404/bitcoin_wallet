import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_bloc.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_event.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_state.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/view/widget/utxo_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UtxoSection extends StatelessWidget {
  const UtxoSection({super.key, required this.walletId, required this.state});

  final String walletId;
  final SigningState state;

  @override
  Widget build(BuildContext context) {
    final isLoading = state.status == SigningStatus.scanning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: isLoading ? null : () => context.read<SigningBloc>().add(UtxoScanRequested(walletId: walletId)),
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(isLoading ? 'Scanning…' : 'Scan UTXOs'),
        ),
        if (state.utxos.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Found ${state.utxos.length} UTXO(s)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...state.utxos.map(UtxoTile.new),
        ] else if (state.status == SigningStatus.scanned) ...[
          const SizedBox(height: 16),
          const Text('No UTXOs found at native SegWit addresses.'),
        ],
      ],
    );
  }
}
