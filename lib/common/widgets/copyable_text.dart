import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tappable text that copies [text] to the clipboard on tap.
///
/// Shows a confirmation snackbar after copying.
class CopyableText extends StatelessWidget {
  const CopyableText({super.key, required this.text});

  final String text;

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => unawaited(_copyToClipboard(context)),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.copy, size: 16),
        ],
      ),
    ),
  );
}
