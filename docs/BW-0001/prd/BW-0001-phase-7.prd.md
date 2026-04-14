# BW-0001 Phase 7 PRD — Navigation & Integration

Status: `PRD_READY`
Ticket: BW-0001
Phase: 7
Lane: Professional
Workflow Version: 3
Owner: Analyst

---

## Phase Intent

Wire all Phase 6 screens into a working app: add `AppRouter`, replace the placeholder home with
`WalletListScreen`, inject `WalletScope`, and fill `AppDependenciesBuilder` with the real HD
and Seed repository implementations created in Phase 4.

---

## Deliverables

1. `lib/core/routing/app_router.dart` — static navigation helpers and route name constants.
2. `lib/app.dart` (modified) — `App` becomes a `StatefulWidget`; creates one `WalletBloc` and
   one `WalletScopeBlocFactory`; wraps `MaterialApp` with `WalletScope`; sets `WalletListScreen`
   as home with wired callbacks.
3. `lib/core/di/app_dependencies_builder.dart` (modified) — replace `_StubHdWalletRepository`
   and `_StubSeedRepository` with `HdWalletRepositoryImpl` and `SeedRepositoryImpl`.

---

## Scenarios

### Positive

- App launches → `WalletListScreen` shown; empty state "No wallets yet" visible; FAB visible.
- FAB tapped → `CreateWalletScreen` pushed; user enters name, selects Node, taps Create →
  `WalletDetailScreen` pushed (replacing CreateWalletScreen); wallet visible; Generate buttons active.
- Back from `WalletDetailScreen` → `WalletListScreen` refreshes and shows the new wallet.
- FAB → Create HD wallet → `SeedPhraseScreen` pushed; checkbox → Continue → `WalletListScreen`
  shown; HD wallet visible.
- Wallet tapped in list → `WalletDetailScreen`; address tapped → `AddressScreen`; Copy works.
- HD wallet detail → View Seed → `SeedPhraseScreen` shown with existing mnemonic.
- Node wallet detail → "View Seed" button absent.

### Negative / Edge

- `SeedPhraseScreen` opened for View Seed: `pendingWallet` is null (no pending creation);
  screen receives only `mnemonic` and `walletId` — works correctly.
- App killed and restarted: wallets persist (repository-backed); HD seed persists in
  `flutter_secure_storage`.

---

## Success Metrics

| Criterion | Verification |
|-----------|--------------|
| App launches without runtime error | Manual launch on macOS |
| `WalletListScreen` is the initial route | Visual inspection |
| Full flow: create Node wallet → address generated | Manual |
| Full flow: create HD wallet → seed shown → confirmed → wallet in list | Manual |
| `flutter analyze --fatal-infos --fatal-warnings` exits 0 | CI / terminal |
| No stubs remain in `AppDependenciesBuilder` | Code review |

---

## Constraints

- `AppRouter` must use `Navigator.push` / `Navigator.pushReplacement` / `Navigator.pop` —
  no named routes required; route name constants are optional documentation aids.
- No `!` null assertion anywhere in new or modified code.
- No `dynamic`.
- All imports: `package:` only.
- `WalletBloc` lifecycle: one instance per app session, owned by `_AppState`, passed to screens
  via constructor; each screen wraps with `BlocProvider(create: (_) => widget.bloc)`.
- `CreateWalletScreen` receives its OWN fresh `WalletBloc` (from factory); after it resolves,
  `_AppState` fires `WalletListRequested` on the list bloc to refresh.
- `AddressBloc` is per-wallet, created fresh in `AppRouter` for each `WalletDetailScreen`.

---

## Out Of Scope

- Deep linking or named-route argument decoding.
- QR code rendering.
- Transaction history or balance.
- Theming / `ui_kit` integration.
