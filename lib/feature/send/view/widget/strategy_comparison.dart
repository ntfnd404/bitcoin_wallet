import 'package:bitcoin_wallet/feature/send/bloc/send_bloc.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_event.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';

class StrategyComparison extends StatelessWidget {
  const StrategyComparison({super.key, required this.state});

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
        _cell(name, textTheme, bold: true, onTap: () {
          context.read<SendBloc>().add(SendStrategySelected(strategyName: name));
        }),
        _cell('${result.inputs.length}', textTheme),
        _cell('${result.changeSat.value} sat', textTheme),
        _cell('${result.feeSat.value} sat', textTheme),
      ],
    );
  }

  Widget _cell(String text, TextTheme textTheme, {bool bold = false, VoidCallback? onTap}) =>
      GestureDetector(
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
          border: TableBorder.all(color: Theme.of(context).dividerColor, width: 0.5),
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
