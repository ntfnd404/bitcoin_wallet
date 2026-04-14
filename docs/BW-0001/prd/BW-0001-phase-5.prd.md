# BW-0001 Phase 5 PRD — BLoC

Status: `PRD_READY`
Ticket: BW-0001
Phase: 5
Lane: Professional
Workflow Version: 3
Owner: Analyst

---

## Phase Intent

Build the presentation-logic layer that sits between the UI (Phase 6) and the
fully-implemented data layer (Phase 4). This phase delivers two BLoC classes —
`WalletBloc` and `AddressBloc` — and a feature-scoped DI widget `WalletScope`.

After Phase 5, every UI screen has a well-defined state machine to bind to.
No domain or data code is introduced in this phase.

---

## Deliverables

1. `WalletBloc` — manages wallet list, wallet creation (node and HD), HD seed
   confirmation flow, and seed view requests.
2. `AddressBloc` — manages address list for a wallet and address generation.
3. `WalletScope` — `InheritedWidget` that provides a `WalletScopeBlocFactory`
   to the subtree; factory creates `WalletBloc` and `AddressBloc` with injected
   repositories/services received from `AppScope`.

---

## Scenarios

### Positive

- User requests wallet list: `WalletBloc` emits `loading` then `loaded` with
  combined list from both repositories.
- User creates a node wallet: `WalletBloc` emits `creating` then `loaded`.
- User creates an HD wallet: `WalletBloc` emits `creating` then
  `awaitingSeedConfirmation` with `pendingWallet` and `pendingMnemonic` set.
- User confirms seed phrase: `WalletBloc` clears pending state and emits `loaded`.
- User requests address list: `AddressBloc` emits `loading` then `loaded`.
- User generates an address: `AddressBloc` emits `generating` then `loaded`
  with `lastGenerated` populated.

### Negative / Edge

- Repository throws during wallet creation: `WalletBloc` emits `error` with a
  non-null `errorMessage`; `pendingWallet` and `pendingMnemonic` are cleared.
- `AddressBloc` receives `AddressGenerateRequested` while already `generating`:
  the second event is ignored (guard with status check at handler entry).
- `WalletBloc` receives any mutation event while `creating`: event is queued by
  `flutter_bloc` naturally — no special guard required.
- `SeedViewRequested` for a wallet with no stored seed: `WalletBloc` emits
  `error` with message `'Seed not found for wallet'`.
- `emit()` called after `close()`: guarded by `isClosed` checks after every
  `await` in each handler.

---

## Success Metrics

| Criterion | Verification |
|-----------|--------------|
| `HdWalletCreateRequested` → status becomes `awaitingSeedConfirmation` | Manual run or unit test |
| `SeedConfirmed` → `pendingMnemonic` is null, status `loaded` | Manual run or unit test |
| `AddressGenerateRequested` → `lastGenerated.derivationPath` non-null for HD | Manual run |
| `AddressGenerateRequested` on Node wallet → `lastGenerated.derivationPath` null | Manual run |
| `flutter analyze --fatal-infos --fatal-warnings` passes | CI / local |
| No mnemonic material appears in logs or error messages | Code review |

---

## Constraints

- BLoC only — no Cubits.
- All event names in past-tense imperative style (`WalletListRequested`).
- `isClosed` must be checked before every `emit()` that follows an `await`.
- `WalletBloc` must not hold a reference to `Mnemonic` beyond the
  `awaitingSeedConfirmation` state; it is cleared on `SeedConfirmed`.
- `WalletScope` receives dependencies from `AppScope` at construction time —
  no service-locator pattern.
- `BlocProvider(create: ...)` only — never `BlocProvider.value`.
- No `freezed` or code-generation — hand-written immutable state with `copyWith`.

---

## Out Of Scope

- UI screens (Phase 6).
- Navigator wiring (Phase 7).
- Error localisation or user-facing error strings beyond a raw message field.
- Unit tests for BLoC (may be added as an optional task, not blocking `PLAN_APPROVED`).

---

## Open Questions

- [ ] None
