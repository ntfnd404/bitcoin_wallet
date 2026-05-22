import 'package:bitcoin_wallet/feature/utxo/view/widget/utxo_picker_total_column.dart';
import 'package:flutter/material.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// Displays the running total for the UTXO picker: input sum, fee estimate,
/// and change estimate.
class UtxoPickerTotalRow extends StatelessWidget {
  const UtxoPickerTotalRow({
    super.key,
    required this.inputSumSat,
    required this.estimatedFeeSat,
    required this.estimatedChangeSat,
  });

  final Satoshi inputSumSat;
  final Satoshi estimatedFeeSat;
  final Satoshi estimatedChangeSat;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          UtxoPickerTotalColumn(
            label: 'Input',
            value: '${inputSumSat.btcDisplay} BTC',
            textTheme: textTheme,
          ),
          UtxoPickerTotalColumn(
            label: 'Est. fee',
            value: '${estimatedFeeSat.value} sat',
            textTheme: textTheme,
          ),
          UtxoPickerTotalColumn(
            label: 'Est. change',
            value: '${estimatedChangeSat.btcDisplay} BTC',
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }
}
