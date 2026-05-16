import 'package:bitcoin_wallet/feature/send/bloc/send_bloc.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController recipientController;
  final TextEditingController amountController;
  final TextEditingController feeRateController;
  final Wallet wallet;
  final bool isLoading;

  void _submit(BuildContext context) {
    if (!formKey.currentState!.validate()) return;

    final amount = int.tryParse(amountController.text.trim());
    final feeRate = int.tryParse(feeRateController.text.trim());
    if (amount == null || feeRate == null) return;

    context.read<SendBloc>().add(
      SendFormSubmitted(
        recipientAddress: recipientController.text.trim(),
        amountSat: amount,
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
        ElevatedButton.icon(
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
      ],
    ),
  );
}
