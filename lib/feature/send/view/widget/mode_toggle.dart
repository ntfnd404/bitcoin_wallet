import 'package:bitcoin_wallet/feature/send/bloc/coin_selection_mode.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_bloc.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Auto/Manual strategy selection toggle for the send comparison screen.
class ModeToggle extends StatelessWidget {
  const ModeToggle({super.key, required this.isAuto});

  final bool isAuto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _ModeChip(
        label: 'Auto',
        selected: isAuto,
        onTap: () => context.read<SendBloc>().add(
          const SendSelectionModeChanged(mode: CoinSelectionMode.auto),
        ),
      ),
      const SizedBox(width: 4),
      _ModeChip(
        label: 'Manual',
        selected: !isAuto,
        onTap: () => context.read<SendBloc>().add(
          const SendSelectionModeChanged(mode: CoinSelectionMode.manual),
        ),
      ),
    ],
  );
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: selected ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
