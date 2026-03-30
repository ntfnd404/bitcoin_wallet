import 'package:flutter/material.dart';

import 'core/di/app_dependencies.dart';
import 'core/di/app_scope.dart';

/// Root application widget.
///
/// Wraps [MaterialApp] with [AppScope] so dependencies are accessible
/// throughout the entire widget tree.
class App extends StatelessWidget {
  const App({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: dependencies,
      child: const MaterialApp(
        home: Scaffold(body: Center(child: Text('Hello World!'))),
      ),
    );
  }
}
