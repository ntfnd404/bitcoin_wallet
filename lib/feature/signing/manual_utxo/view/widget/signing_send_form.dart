import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_bloc.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_event.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SigningSendForm extends StatelessWidget {
  const SigningSendForm({
    super.key,
    required this.formKey,
    required this.recipientController,
    required this.amountController,
    required this.walletId,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController recipientController;
  final TextEditingController amountController;
  final String walletId;

  void _submit(BuildContext context) {
    if (formKey.currentState == null || !formKey.currentState!.validate()) return;

    final amount = int.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) return;

    context.read<SigningBloc>().add(
      SignAndBroadcastRequested(
        walletId: walletId,
        recipientAddress: recipientController.text.trim(),
        amountSat: amount,
        bech32Hrp: AppScope.of(context).network.bech32Hrp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSigning = context.watch<SigningBloc>().state.status == SigningStatus.signing;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Send', style: Theme.of(context).textTheme.titleMedium),
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
          TextFormField(
            controller: amountController,
            decoration: const InputDecoration(
              labelText: 'Amount (sat)',
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
          ElevatedButton.icon(
            onPressed: isSigning ? null : () => _submit(context),
            icon: isSigning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(isSigning ? 'Signing…' : 'Sign & Broadcast'),
          ),
        ],
      ),
    );
  }
}
