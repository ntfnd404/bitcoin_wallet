import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_bloc.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_event.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_state.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_status.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/view/widget/op_return_byte_counter.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/view/widget/op_return_hex_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Input form for the OP_RETURN transaction flow.
///
/// Contains the data text field, fee-rate field, byte counter, hex preview,
/// and the Broadcast button. Dispatches events to [OpReturnBloc].
class OpReturnForm extends StatefulWidget {
  const OpReturnForm({super.key});

  @override
  State<OpReturnForm> createState() => _OpReturnFormState();
}

class _OpReturnFormState extends State<OpReturnForm> {
  late final TextEditingController _textController;
  late final TextEditingController _feeRateController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _feeRateController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _textController.dispose();
    _feeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = context.select((OpReturnState s) => s.status);
    final isValid = context.select((OpReturnState s) => s.isValid);
    final isBusy = status == OpReturnStatus.processing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _textController,
          decoration: const InputDecoration(
            labelText: 'Data (UTF-8 text)',
            hintText: 'Hello Bitcoin',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (v) =>
              context.read<OpReturnBloc>().add(OpReturnDataChanged(v)),
        ),
        const SizedBox(height: 8),
        const OpReturnByteCounter(),
        const SizedBox(height: 16),
        const OpReturnHexPreview(),
        const SizedBox(height: 16),
        TextField(
          controller: _feeRateController,
          decoration: const InputDecoration(
            labelText: 'Fee rate (sat/vbyte)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) {
            final n = int.tryParse(v);
            if (n != null && n >= 1) {
              context.read<OpReturnBloc>().add(OpReturnFeeRateChanged(n));
            }
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: isBusy || !isValid
              ? null
              : () => context
                  .read<OpReturnBloc>()
                  .add(const OpReturnBroadcastRequested()),
          icon: isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.broadcast_on_personal),
          label: Text(isBusy ? 'Broadcasting…' : 'Broadcast'),
        ),
      ],
    );
  }
}
