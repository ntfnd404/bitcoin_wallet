import 'package:bitcoin_wallet/common/widgets/detail_section.dart';
import 'package:bitcoin_wallet/core/constants/app_constants.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_bloc.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_event.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_state.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/di/manual_utxo_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// HD wallet sign-and-broadcast demo.
///
/// Scans the UTXO set for stored native SegWit addresses, then lets the user
/// specify a recipient and amount to create, sign, and broadcast a transaction.
class SigningDemoScreen extends StatefulWidget {
  const SigningDemoScreen({super.key, required this.wallet});

  final Wallet wallet;

  @override
  State<SigningDemoScreen> createState() => _SigningDemoScreenState();
}

class _SigningDemoScreenState extends State<SigningDemoScreen> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<SigningBloc>(
        create: (ctx) => ManualUtxoScope.newSigningBloc(ctx),
        child: Scaffold(
          appBar: AppBar(title: const Text('Sign & Send')),
          body: BlocConsumer<SigningBloc, SigningState>(
            listener: (context, state) {
              if (state.status == SigningStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage ?? 'Unknown error'),
                  ),
                );
              }
            },
            builder: (context, state) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _UtxoSection(
                    walletId: widget.wallet.id,
                    state: state,
                  ),
                  if (state.status == SigningStatus.scanned &&
                      state.utxos.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SendForm(
                      formKey: _formKey,
                      recipientController: _recipientController,
                      amountController: _amountController,
                      walletId: widget.wallet.id,
                    ),
                  ],
                  if (state.status == SigningStatus.broadcasted &&
                      state.txid != null) ...[
                    const SizedBox(height: 24),
                    _BroadcastResult(state: state),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _UtxoSection extends StatelessWidget {
  const _UtxoSection({required this.walletId, required this.state});

  final String walletId;
  final SigningState state;

  @override
  Widget build(BuildContext context) {
    final isLoading = state.status == SigningStatus.scanning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () => context
                  .read<SigningBloc>()
                  .add(UtxoScanRequested(walletId: walletId)),
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
          ...state.utxos.map(_UtxoTile.new),
        ] else if (state.status == SigningStatus.scanned) ...[
          const SizedBox(height: 16),
          const Text('No UTXOs found at native SegWit addresses.'),
        ],
      ],
    );
  }
}

class _UtxoTile extends StatelessWidget {
  const _UtxoTile(this.utxo);

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
                  style:
                      const TextStyle(fontFamily: 'monospace', fontSize: 11),
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

class _SendForm extends StatelessWidget {
  const _SendForm({
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

    context.read<SigningBloc>().add(SignAndBroadcastRequested(
          walletId: walletId,
          recipientAddress: recipientController.text.trim(),
          amountSat: amount,
          bech32Hrp: AppConstants.network.bech32Hrp,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isSigning =
        context.watch<SigningBloc>().state.status == SigningStatus.signing;

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
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
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

class _BroadcastResult extends StatelessWidget {
  const _BroadcastResult({required this.state});

  final SigningState state;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Broadcasted',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.green),
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
