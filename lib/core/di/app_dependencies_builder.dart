import 'app_dependencies.dart';

/// Composition root — creates and wires all concrete implementations.
///
/// Called once at startup in [main]. Implementations are added here
/// as phases 3–4 are completed. The [AppDependencies] container returned
/// is then passed into [AppScope] for distribution through the widget tree.
final class AppDependenciesBuilder {
  /// Builds and returns the fully wired [AppDependencies].
  AppDependencies build() {
    // Implementations are added here in Phases 3–4 as each repository
    // and service is completed.
    return const AppDependencies();
  }
}
