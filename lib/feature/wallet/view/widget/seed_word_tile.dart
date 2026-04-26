import 'package:flutter/material.dart';

/// Displays an indexed BIP39 word inside the mnemonic grid.
class SeedWordTile extends StatelessWidget {
  const SeedWordTile({super.key, required this.index, required this.word});

  /// 1-based word index.
  final int index;
  final String word;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      '$index. $word',
      style: const TextStyle(fontFamily: 'monospace'),
    ),
  );
}
