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
        _StrategyTable(
          strategies: strategies,
          failedStrategies: state.failedStrategies ?? const [],
          selectedStrategy: state.selectedStrategy,
          isAuto: isAuto,
        ),
      ],
    );
  }
}

class _StrategyTable extends StatelessWidget {
  const _StrategyTable({
    required this.strategies,
    required this.failedStrategies,
    required this.selectedStrategy,
    required this.isAuto,
  });

  final List<CoinSelectionStrategyResult> strategies;
  final List<String> failedStrategies;
  final String? selectedStrategy;
  final bool isAuto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final headerStyle = textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header row
          ColoredBox(
            color: const Color(0xFFEEEEEE),
            child: Row(
              children: [
                _HeaderCell(text: 'Strategy', flex: 2, style: headerStyle),
                _HeaderCell(text: 'Inputs', flex: 1, style: headerStyle),
                _HeaderCell(text: 'Change', flex: 2, style: headerStyle),
                _HeaderCell(text: 'Fee', flex: 2, style: headerStyle),
              ],
            ),
          ),
          const Divider(height: 0.5, thickness: 0.5),
          // Data rows — successful strategies
          ...strategies.map((e) {
            final isSelected = selectedStrategy == e.name;
            final isRecommended = isAuto && isSelected;

            return _StrategyRow(
              name: e.name,
              result: e.result,
              isStochastic: e.isStochastic,
              isSelected: isSelected,
              isRecommended: isRecommended,
            );
          }),
          // Failed strategies — shown greyed out so the user knows they exist
          ...failedStrategies.map(_FailedStrategyRow.new),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.text, required this.flex, this.style});

  final String text;
  final int flex;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Text(text, style: style),
    ),
  );
}

class _StrategyRow extends StatelessWidget {
  const _StrategyRow({
    required this.name,
    required this.result,
    required this.isStochastic,
    required this.isSelected,
    required this.isRecommended,
  });

  final String name;
  final CoinSelectionResult result;
  final bool isStochastic;
  final bool isSelected;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Material(
      color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: () => context.read<SendBloc>().add(SendStrategySelected(strategyName: name)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 4),
                        _Badge(
                          label: 'Auto',
                          bg: theme.colorScheme.primary,
                          fg: theme.colorScheme.onPrimary,
                        ),
                      ],
                      if (isStochastic) ...[
                        const SizedBox(width: 4),
                        _Badge(
                          label: '~',
                          bg: theme.colorScheme.tertiary,
                          fg: theme.colorScheme.onTertiary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _DataCell(text: '${result.inputs.length}', flex: 1),
              _DataCell(text: '${result.changeSat.value} sat', flex: 2),
              _DataCell(text: '${result.feeSat.value} sat', flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailedStrategyRow extends StatelessWidget {
  const _FailedStrategyRow(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final grey = textTheme.bodySmall?.copyWith(color: Colors.grey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: grey?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _Badge(
                    label: 'No match',
                    bg: Colors.grey.shade300,
                    fg: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: Padding(padding: const EdgeInsets.all(6), child: Text('—', style: grey))),
          Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(6), child: Text('—', style: grey))),
          Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(6), child: Text('—', style: grey))),
        ],
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell({required this.text, required this.flex});

  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontSize: 9),
    ),
  );
}
