import 'package:bitcoin_wallet/common/widgets/detail_section.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/view/widget/transaction_input_tile.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/view/widget/transaction_output_tile.dart';
import 'package:flutter/material.dart';
import 'package:transaction/transaction.dart';

class TransactionDetailBody extends StatelessWidget {
  const TransactionDetailBody({super.key, required this.detail});

  final TransactionDetail detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        DetailSection(
          title: 'Size',
          child: Text('${detail.size} bytes'),
        ),
        const SizedBox(height: 16),
        DetailSection(
          title: 'Weight',
          child: Text('${detail.weight} WU'),
        ),
        const SizedBox(height: 16),
        DetailSection(
          title: 'Inputs (${detail.inputs.length})',
          child: Column(
            children: [
              for (final input in detail.inputs) TransactionInputTile(input: input, textTheme: textTheme),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DetailSection(
          title: 'Outputs (${detail.outputs.length})',
          child: Column(
            children: [
              for (final output in detail.outputs) TransactionOutputTile(output: output, textTheme: textTheme),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DetailSection(
          title: 'Raw Hex',
          child: CopyableText(text: detail.hex),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
