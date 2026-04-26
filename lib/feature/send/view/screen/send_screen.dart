import 'package:bitcoin_wallet/feature/send/bloc/send_bloc.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_event.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_state.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_status.dart';
import 'package:bitcoin_wallet/feature/send/di/send_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// Two-step send flow: form → strategy comparison → confirm → broadcast.
///
/// Creates its own [SendBloc] via [SendScope] — lifecycle is managed by
/// [BlocProvider].
class SendScreen extends StatefulWidget {
  const SendScreen({super.key, required this.wallet});

  final Wallet wallet;

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _feeRateController = TextEditingController(text: '10');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _feeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<SendBloc>(
    create: (_) => SendScope.newSendBloc(context, widget.wallet),
    child: Scaffold(
      appBar: AppBar(title: const Text('Send')),
      body: BlocConsumer<SendBloc, SendState>(
        listener: (context, state) {
          if (state.status == SendStatus.error) {
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
              if (state.status == SendStatus.initial ||
                  state.status == SendStatus.preparing ||
                  state.status == SendStatus.error)
                _SendForm(
                  formKey: _formKey,
                  recipientController: _recipientController,
                  amountController: _amountController,
                  feeRateController: _feeRateController,
                  wallet: widget.wallet,
                  isLoading: state.status == SendStatus.preparing,
                ),
              if (state.status == SendStatus.awaitingConfirmation || state.status == SendStatus.sending) ...[
                _StrategyComparison(state: state),
                const SizedBox(height: 24),
                _SendSummary(state: state, wallet: widget.wallet),
              ],
              if (state.status == SendStatus.sent ||
                  state.status == SendStatus.mining ||
                  state.status == SendStatus.mined)
                _BroadcastResult(
                  state: state,
                  changeAddress: state.changeAddress ?? '',
                ),
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

class _SendForm extends StatelessWidget {
  const _SendForm({
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
        wallet: wallet,
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

class _StrategyComparison extends StatelessWidget {
  const _StrategyComparison({required this.state});

  final SendState state;

  TableRow _headerRow(TextTheme textTheme) => TableRow(
    decoration: const BoxDecoration(color: Color(0xFFEEEEEE)),
    children: ['Strategy', 'Inputs', 'Change', 'Fee']
        .map(
          (h) => Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              h,
              style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        )
        .toList(),
  );

  TableRow _dataRow(
    BuildContext context, {
    required String name,
    required CoinSelectionResult result,
    required bool isSelected,
    required TextTheme textTheme,
  }) {
    final bg = isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent;

    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        _cell(
          name,
          textTheme,
          bold: true,
          onTap: () {
            context.read<SendBloc>().add(SendStrategySelected(strategyName: name));
          },
        ),
        _cell('${result.inputs.length}', textTheme),
        _cell('${result.changeSat.value} sat', textTheme),
        _cell('${result.feeSat.value} sat', textTheme),
      ],
    );
  }

  Widget _cell(
    String text,
    TextTheme textTheme, {
    bool bold = false,
    VoidCallback? onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        style: textTheme.bodySmall?.copyWith(
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final strategies = state.strategies;
    if (strategies == null || strategies.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Strategy Comparison', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2),
          },
          children: [
            _headerRow(textTheme),
            ...strategies.entries.map(
              (e) => _dataRow(
                context,
                name: e.key,
                result: e.value,
                isSelected: state.selectedStrategy == e.key,
                textTheme: textTheme,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SendSummary extends StatelessWidget {
  const _SendSummary({required this.state, required this.wallet});

  final SendState state;
  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final strategy = state.selectedStrategy;
    final result = state.strategies?[strategy];
    final isSending = state.status == SendStatus.sending;

    if (result == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Summary — $strategy',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _SummaryRow(label: 'Inputs', value: '${result.inputs.length}'),
        _SummaryRow(
          label: 'To recipient',
          value: '${state.amountSat} sat',
        ),
        _SummaryRow(
          label: 'Change',
          value: result.changeSat.value > 0 ? '${result.changeSat.value} sat' : '(none — absorbed into fee)',
        ),
        _SummaryRow(label: 'Fee', value: '${result.feeSat.value} sat'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: isSending ? null : () => context.read<SendBloc>().add(const SendConfirmed()),
          icon: isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(isSending ? 'Sending…' : 'Confirm & Send'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}

class _BroadcastResult extends StatelessWidget {
  const _BroadcastResult({
    required this.state,
    required this.changeAddress,
  });

  final SendState state;
  final String changeAddress;

  @override
  Widget build(BuildContext context) {
    final isMining = state.status == SendStatus.mining;
    final isMined = state.status == SendStatus.mined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Broadcasted',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green),
        ),
        const SizedBox(height: 8),
        if (state.txid != null)
          SelectableText(
            state.txid!,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        const SizedBox(height: 16),
        if (isMined)
          Text(
            'Block mined!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green),
          )
        else
          ElevatedButton.icon(
            onPressed: isMining || changeAddress.isEmpty
                ? null
                : () => context.read<SendBloc>().add(
                    MineBlockRequested(toAddress: changeAddress),
                  ),
            icon: isMining
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.settings_outlined),
            label: Text(isMining ? 'Mining…' : 'Mine 1 block'),
          ),
      ],
    );
  }
}
