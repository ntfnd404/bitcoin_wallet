import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the UTF-8 byte count of the current OP_RETURN text.
///
/// Shows "N / 80 bytes". Colour changes to warning at 75+ bytes and to
/// error when the limit is exceeded (byteCount > 80).
class OpReturnByteCounter extends StatelessWidget {
  const OpReturnByteCounter({super.key});

  @override
  Widget build(BuildContext context) {
    final byteCount = context.select((OpReturnState s) => s.byteCount);
    final colorScheme = Theme.of(context).colorScheme;

    final Color color;
    if (byteCount > 80) {
      color = colorScheme.error;
    } else if (byteCount >= 75) {
      color = colorScheme.tertiary;
    } else {
      color = colorScheme.onSurfaceVariant;
    }

    return Text(
      '$byteCount / 80 bytes',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
    );
  }
}
