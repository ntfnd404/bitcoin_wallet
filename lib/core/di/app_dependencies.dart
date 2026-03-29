/// Immutable container that holds all application-level dependencies.
///
/// Fields correspond to domain interfaces from the `domain` package.
/// Populated progressively as repository and service implementations are added
/// in Phases 3–4. Passed down the widget tree via [AppScope].
final class AppDependencies {
  const AppDependencies();
}
