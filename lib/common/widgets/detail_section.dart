import 'package:flutter/material.dart';

/// Labelled section used on detail screens.
///
/// Renders a small grey label above [child].
class DetailSection extends StatelessWidget {
  const DetailSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.grey,
        ),
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}
