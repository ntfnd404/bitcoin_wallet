import 'package:flutter/widgets.dart';

import 'app_dependencies.dart';

/// InheritedWidget that propagates [AppDependencies] down the widget tree.
///
/// Wrap the root [MaterialApp] with [AppScope] so that any widget can call
/// [AppScope.of] to obtain the resolved dependency container.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencies, required super.child});

  final AppDependencies dependencies;

  /// Returns [AppDependencies] from the nearest [AppScope] ancestor.
  ///
  /// Throws [StateError] if no [AppScope] is present in the widget tree.
  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw StateError('AppScope not found in widget tree');
    }

    return scope.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => dependencies != oldWidget.dependencies;
}
