import 'package:bitcoin_wallet/feature/send/bloc/send_bloc.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/wallet.dart';

class SendForm extends StatelessWidget {
  const SendForm({
    super.key,
    required this.formKey,
    required this.recipientController,
    required this.amountController,
    required this.feeRateController,
    required this.wallet,
    required this.isLoading,
    required this.canSend,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController recipientController;
  final TextEditingController amountController;
  final TextEditingController feeRateController;
  final Wallet wallet;
  final bool isLoading;
  final bool canSend;

  void _submit(BuildContext context) {
    final formState = formKey.currentState;
    if (formState == null || !formState.validate()) return;

    final btcValue = double.tryParse(amountController.text.trim());
    final feeRate = int.tryParse(feeRateController.text.trim());
    if (btcValue == null || feeRate == null) return;

    context.read<SendBloc>().add(
      SendFormSubmitted(
        recipientAddress: recipientController.text.trim(),
        amountSat: Satoshi.fromBtc(btcValue).value,
        feeRateSatPerVbyte: feeRate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: ExpansionTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('How to send'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wallet is NodeWallet)
                      const Text('1. Fund wallet: Wallet Detail → Mine block')
                    else
                      const Text('1. Fund wallet: receive BTC to your HD address'),
                    const Text('2. Enter recipient address and amount (sat)'),
                    const Text('3. Tap Calculate — fee strategies will appear'),
                    const Text('4. Tap Send to broadcast the transaction'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: recipientController,
          decoration: const InputDecoration(
            labelText: 'Recipient address',
            hintText: 'bcrt1q…',
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: Listenable.merge([amountController, recipientController]),
          builder: (context, _) {
            final btc = double.tryParse(amountController.text.trim());
            final satoshiLabel = btc != null && btc > 0
                ? '= ${Satoshi.fromBtc(btc).value} sat'
                : null;
            final dustSat = _dustThresholdForAddress(recipientController.text.trim());
            final dustBtc = Satoshi(dustSat).btcDisplay;

            return TextFormField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount (BTC)',
                hintText: '0.001',
                border: const OutlineInputBorder(),
                helperText: satoshiLabel,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final btcVal = double.tryParse(v ?? '');
                if (btcVal == null || btcVal <= 0) return 'Enter a positive BTC amount';
                final sats = Satoshi.fromBtc(btcVal).value;
                if (sats < dustSat) return 'Minimum $dustBtc BTC (dust limit for this address)';

                return null;
              },
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: feeRateController,
          decoration: const InputDecoration(
            labelText: 'Fee rate (sat/vbyte)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (v) {
            final n = int.tryParse(v ?? '');
            if (n == null || n <= 0) return 'Enter a positive integer';

            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => _submit(context),
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calculate_outlined),
                label: Text(isLoading ? 'Calculating…' : 'Calculate'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canSend
                    ? () => context.read<SendBloc>().add(const SendConfirmed())
                    : null,
                icon: const Icon(Icons.send),
                label: const Text('Send'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Returns the Bitcoin Core dust threshold in satoshis for the given address.
///
/// Detection is based on the bech32 version character immediately after the
/// `1` separator:
/// - `p` → witness v1 (Taproot / P2TR): 330 sat
/// - `q` → witness v0 (Native SegWit / P2WPKH): 294 sat
/// - anything else (legacy P2PKH / P2SH): 546 sat
int _dustThresholdForAddress(String address) {
  final lower = address.toLowerCase();
  if (lower.startsWith('bc1p') || lower.startsWith('tb1p') || lower.startsWith('bcrt1p')) {
    return 330;
  }
  if (lower.startsWith('bc1q') || lower.startsWith('tb1q') || lower.startsWith('bcrt1q')) {
    return 294;
  }

  return 546;
}
