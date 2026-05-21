import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the live OP_RETURN scriptPubKey hex preview.
///
/// Shows a placeholder when no valid data is entered.
class OpReturnHexPreview extends StatelessWidget {
  const OpReturnHexPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final hexPreview = context.select((OpReturnState s) => s.hexPreview);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Script hex preview',
          style: textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          hexPreview.isEmpty ? '(enter text to see hex preview)' : hexPreview,
          style: textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: hexPreview.isEmpty
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : null,
          ),
        ),
      ],
    );
  }
}
