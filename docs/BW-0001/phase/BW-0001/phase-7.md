# Phase 7: Navigation & Integration

Status: `IMPLEMENTATION_DONE`
Ticket: BW-0001
Phase: 7
Lane: Professional
Workflow Version: 3
Owner: Implementer

---

## Goal

Wire all screens, routing, and DI into a runnable app: AppRouter + WalletScope + real repository implementations.

## Context

Completes BW-0001: app launches with WalletListScreen, full wallet create/restore/seed flows navigable.

## Tasks

- [x] 7.1 Create `lib/core/routing/app_router.dart`
- [x] 7.2 Modify `lib/app.dart` — App → StatefulWidget + WalletScope + WalletListScreen home
- [x] 7.3 Modify `lib/core/di/app_dependencies_builder.dart` — replace stubs
- [x] Fix pre-existing DCM issues in Phase 5 BLoC files and Phase 2 DI files
- [x] `flutter analyze --fatal-infos --fatal-warnings` — zero issues
- [x] `dcm analyze lib/` — zero issues

## Acceptance Criteria

- App launches without error; WalletListScreen shown
- Full navigation flow wired via AppRouter
- No stubs in AppDependenciesBuilder
- `flutter analyze` + `dcm analyze` both clean

## Dependencies

- Phase 5 (BLoC), Phase 6 (screens)

## Technical Details

- WalletBloc lifecycle: owned by `_AppState`, passed to WalletListScreen; after toCreateWallet resolves, WalletListRequested fires to refresh
- Fresh WalletBloc per CreateWalletScreen/RestoreWalletScreen (repo-backed, no shared state needed)
- DCM member order for non-widget classes: private-fields → constructor → methods
- DCM member order for InheritedWidget: constructor → static methods → final fields → overrides
- `_onViewSeed` uses `addPostFrameCallback` to read pendingMnemonic after BLoC processes SeedViewRequested
