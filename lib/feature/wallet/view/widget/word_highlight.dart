import 'package:flutter/material.dart';

/// Renders the phrase with invalid words highlighted in red.
class WordHighlight extends StatelessWidget {
  const WordHighlight({super.key, required this.words, required this.invalidWords});

  final List<String> words;
  final List<String> invalidWords;

  @override
  Widget build(BuildContext context) {
    final spans = words
        .map(
          (word) => TextSpan(
            text: '$word ',
            style: TextStyle(
              color: invalidWords.contains(word) ? Theme.of(context).colorScheme.error : null,
            ),
          ),
        )
        .toList();

    return Text.rich(TextSpan(children: spans));
  }
}
