import 'package:flutter/material.dart';

/// One labelled figure in the UTXO picker total row.
class UtxoPickerTotalColumn extends StatelessWidget {
  const UtxoPickerTotalColumn({
    super.key,
    required this.label,
    required this.value,
    required this.textTheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 2),
      Text(value, style: textTheme.bodySmall),
    ],
  );
}
