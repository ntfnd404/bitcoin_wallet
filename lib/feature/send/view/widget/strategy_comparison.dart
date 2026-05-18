import 'package:bitcoin_wallet/feature/send/bloc/coin_selection_mode.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_bloc.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_event.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_state.dart';
import 'package:bitcoin_wallet/feature/send/view/widget/mode_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';

class StrategyComparison extends StatelessWidget {
  const StrategyComparison({super.key, required this.state});

  final SendState state;

  @override
  Widget build(BuildContext context) {
    final strategies = state.strategies;
    if (strategies == null || strategies.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final isAuto = state.selectionMode == CoinSelectionMode.auto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Strategy Comparison', style: textTheme.titleMedium),
            ),
            ModeToggle(isAuto: isAuto),
          ],
        ),
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
            StrategyHeaderRow(textTheme: textTheme),
            ...strategies.entries.map(
              (e) => StrategyDataRow(
                context: context,
                name: e.key,
                result: e.value,
                isSelected: state.selectedStrategy == e.key,
                isRecommended: isAuto && state.selectedStrategy == e.key,
                textTheme: textTheme,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StrategyHeaderRow extends TableRow {
  StrategyHeaderRow({required TextTheme textTheme})
      : super(
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
}

class StrategyDataRow extends TableRow {
  StrategyDataRow({
    required BuildContext context,
    required String name,
    required CoinSelectionResult result,
    required bool isSelected,
    required bool isRecommended,
    required TextTheme textTheme,
  }) : super(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
          ),
          children: [
            GestureDetector(
              onTap: () => context
                  .read<SendBloc>()
                  .add(SendStrategySelected(strategyName: name)),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: isRecommended
                    ? Row(
                        children: [
                          Text(
                            name,
                            style: textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          _AutoBadge(textTheme: textTheme, context: context),
                        ],
                      )
                    : Text(
                        name,
                        style: textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            StrategyCell(text: '${result.inputs.length}', textTheme: textTheme),
            StrategyCell(
                text: '${result.changeSat.value} sat', textTheme: textTheme),
            StrategyCell(
                text: '${result.feeSat.value} sat', textTheme: textTheme),
          ],
        );
}

class StrategyCell extends StatelessWidget {
  const StrategyCell({super.key, required this.text, required this.textTheme});

  final String text;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(6),
        child: Text(text, style: textTheme.bodySmall),
      );
}

class _AutoBadge extends StatelessWidget {
  const _AutoBadge({required this.textTheme, required this.context});

  final TextTheme textTheme;
  final BuildContext context;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Auto',
          style: textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 9,
          ),
        ),
      );
}
