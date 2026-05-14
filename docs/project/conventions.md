# Project Conventions

Architecture and code rules for bitcoin-wallet. Read first, always follow.

For full target architecture, see [architecture.md](./architecture.md).

---

## Project Overview

**Bitcoin Wallet** — Flutter portfolio app demonstrating Bitcoin engineering fundamentals.
Backed by a local Bitcoin Core `regtest` node in Docker.
Platforms: iOS, Android, macOS, Windows, Linux (primary); Web optional.

---

## Wallet Types

### Node Wallet (custodial)
- Bitcoin Core manages keys; Flutter is a UI over JSON-RPC.

### HD Wallet (non-custodial)
- BIP39 mnemonic generated in-app; keys derived locally via BIP32/44/49/84/86.
- Seed stored in `flutter_secure_storage`.

---

## Supported Address Types

| Type | Script | Derivation path (regtest, coin=1) |
|------|--------|-----------------------------------|
| Legacy | P2PKH | `m/44'/1'/0'` |
| Wrapped SegWit | P2SH-P2WPKH | `m/49'/1'/0'` |
| Native SegWit | P2WPKH (Bech32) | `m/84'/1'/0'` |
| Taproot | P2TR (Bech32m) | `m/86'/1'/0'` |

Regtest prefixes: Legacy=`m`, P2SH=`2`, Bech32=`bcrt1q`, Bech32m=`bcrt1p`.

---

## RPC Connection

```
URL:  http://127.0.0.1:18443
Auth: bitcoin:bitcoin (Basic Auth)
```

Regtest only. `txindex=1`. No proxy.

---

## Architecture

Packages-first Flutter workspace monorepo with one app first, business ownership
modeled by packages, layered internals inside each package, and hard import
guardrails. See [architecture.md](./architecture.md) for the full standard.

### Layers (Clean + Hexagonal)

```
Presentation (lib/feature/) → Application/Domain (packages/*) ← Infrastructure (adapter packages)
```

- **Feature** — Flutter UI + BLoC per flow. `lib/feature/`. Depends on module public API only.
- **Module domain** — entities + repository/service/data source interfaces. Pure Dart. `packages/<module>/src/domain/`.
- **Module application** — use cases, query APIs. `packages/<module>/src/application/`.
- **Module data** — implementations. `packages/<module>/src/data/`.
- **Infrastructure** — `bitcoin_node`, `rpc_client`, `storage`: each wraps one external system or platform boundary.
- **Design system** — `ui_kit`: Flutter-only, no domain knowledge.
- **Shared kernel** — `shared_kernel`: tiny shared primitives (BitcoinNetwork, Failure, Result).

See [architecture.md — Project Structure](./architecture.md#project-structure) for the full folder tree.

### Package dependency graph

See [architecture.md — Dependency Graph](./architecture.md#dependency-graph) for the authoritative graph.

### Package type rules

| Type | Packages | Rule |
|------|----------|------|
| **shared** | `shared_kernel` | Tiny shared primitives. Pure Dart. Zero business deps. |
| **business** | `wallet`, `transaction`, `keys` | Own entities, contracts, use cases, and implementations. |
| **infra** | `bitcoin_node`, `rpc_client`, `storage` | Wrap one external system or platform boundary. No business ownership. |
| **ui** | `ui_kit` | Design system only. No domain knowledge. |

### Monorepo topology rules

- Default topology is **Scheme A**: one Flutter app at the repo root and reusable code in `packages/`.
- `packages/` is the correct top-level name for workspace packages. Do not rename it to `components/`.
- Do not create a top-level `components/` directory for business code.
- `lib/feature/*` belongs to the app layer only, not to the whole repository.
- Introduce `apps/` only when a second independently releasable app actually exists.
- Do not adopt `melos` by default. Add it only when pub workspace + `make` stop being enough operationally.

### Feature rules

- Feature = **Bounded Context UI representation**.
- Each feature contains per-flow sub-directories: `list/`, `setup/`, `detail/`, etc.
- Each flow has its own **BLoC + Scope + Presentation** — no god-object BLoC.
- BLoC calls module public API (use cases) directly.
- Optional feature-local `application/` for screen-specific orchestration composing multiple module APIs.
- A feature **must not** contain `data/` — implementations live in module packages.
- A feature **must not** contain `domain/` — entities, interfaces, use cases live in module packages.
- **Feature independence:** Features are independent Bounded Contexts. They do NOT import code from other features' bloc layers. Cross-feature communication only via:
  - `AppEventBus` (event bus for cross-feature notifications)
  - Router (composition point)
  - UI (view importing another feature's shared/ widget is acceptable)
  - DI (scopes wired in AppRouterDelegate)
- Shared app-local helpers may live under `lib/common/*`, but `common/` must not become a second unofficial shared platform layer.

### Ownership rules

- Each entity has **one owner module** — no shared ownership.
- Other modules use: Id, small value objects, public query APIs (ReadApi).
- See [architecture.md](./architecture.md) for full ownership table.

### Gateway and Repository ownership

- **Repository** (`*Repository`) — domain contract for accessing aggregates/entities. Lives in `domain/repository/`.
- **Gateway** (`*Gateway`) — outbound port to an external system (Bitcoin Core RPC, network). Lives in `domain/gateway/`. Owned by the consumer module, not the adapter.
  - Example: `NodeAddressGateway` lives in `address/domain/gateway/`, `bitcoin_node` implements it.
  - This is DIP: high-level module defines the contract, low-level module implements it.
- **DataSource** (`*DataSource`) — infrastructure detail (raw storage, HTTP client). Lives in `data/` as an internal detail of a repository or gateway implementation. Never in `domain/`.
- App code imports package barrels only. `package:<module>/src/*` deep imports from `lib/` or `test/` are forbidden.

### `lib/core/` mandate

`lib/core/` contains **only**:

| Folder | Contents |
|---|---|
| `di/` | Composition root: `AppDependencies`, `AppScope`, `AppDependenciesBuilder` |
| `routing/` | `AppRouter`, `AppRouterDelegate` |
| `event_bus/` | `AppEventBus` and event hierarchy |
| `adapters/` | App-layer composition adapters (bridge between packages that cannot depend on each other directly, and only when a thin passthrough is not enough — adapter must add logic or resolve a dependency cycle) |
| `config/` | `AppEnvironment`, `RpcEnvironment`, `EnvironmentLoader` |
| `error/` | Presentation failure mapper |

**Not allowed in `lib/core/`:**
- UI theme, tokens, fonts → `ui_kit`
- Extensions without architectural role → `lib/common/`
- Domain logic → `packages/*`
- Feature state → `lib/feature/*`

#### App-layer composition adapters — escalation rule

An adapter in `lib/core/adapters/` is acceptable when **all** hold:

1. It bridges two package-level BCs that cannot depend on each other directly,
   or where one direction would create a cycle.
2. It carries real logic (DTO translation, composition of use cases) — not a
   thin passthrough.
3. It is the **only** such bridge between those two BCs.

If 2+ adapters of similar shape accumulate between the same two BCs, extract
their shared contract into a neutral package (e.g. `signing_port`). Do not
extract prematurely on the first one — premature abstraction has a higher cost
than a single documented adapter.

Reference: `HdTransactionSigner` (BW-0011 decision) bridges
`transaction.TransactionSigner` to `keys.SignTransactionUseCase`.

---

## Design Principles

SOLID, KISS, YAGNI, GRASP (High Cohesion, Low Coupling).
Patterns: Repository, Adapter, Factory, Observer, Strategy, Port/Adapter.
See [guidelines.md](./guidelines.md) for detailed examples.

---

## State Management

BLoC only — no Cubits. Events = past-tense user actions (`WalletListRequested`).
Hand-written immutable state classes — no `freezed` or code generation.

```dart
final class WalletState {
  const WalletState({
    this.wallets = const [],
    this.status = WalletStatus.idle,
    this.pendingHdWallet,           // inter-event data lives in State, never as a BLoC field
  });

  final List<Wallet> wallets;
  final WalletStatus status;
  final HdWallet? pendingHdWallet;  // null = no pending wallet; non-null = awaiting seed confirmation

  WalletState copyWith({...});
}

enum WalletStatus { idle, processing }
```

BLoC constructors receive **use cases** (from module application layer). When no orchestration is needed, receiving repositories directly is acceptable.

---

## Dependency Injection

- Constructor-based DI only. No service locator (no GetIt).
- **App-level**: `AppBootstrap` creates infra + module assemblies → `AppDependencies` (container). `AppScope` (InheritedWidget) exposes it to tree.
- **Module-level**: Each module has `*Assembly` class that creates data/ implementations, application/ services, and public API.
- **Feature-level**: Each flow has its own Scope (`StatefulWidget`):
  - Reads `AppDependencies` via `AppScope.of(context)` in `didChangeDependencies` with `_initialized` guard
  - Assembles dependencies (use cases, repositories) needed by the flow's BLoC
  - Exposes a **factory** (static method + `InheritedWidget`) to create BLoC instances
  - Scope does NOT hold or own BLoC instances — it provides a way to CREATE them
  - `BlocProvider(create: ...)` is placed **low** in tree, near the screen that uses the BLoC
  - `BlocProvider(create: ...)` auto-manages BLoC lifecycle (auto-dispose)
  - All screens access BLoC via `context.read<T>()` or `context.watch<T>()`
- **Never** use `BlocProvider.value` — always `BlocProvider(create: ...)`
- **Never** pass BLoCs as constructor params to widgets — use `context.read<T>()`
- Scopes are wired in `AppRouterDelegate.build()`, below `MaterialApp` but above `Navigator`

---

## Event Bus

- `AppEventBus` lives in `core/event_bus/` — no business module owns it
- `StreamController<AppEvent>.broadcast()` — multiple subscribers
- Typed events: `sealed class AppEvent` → `WalletCreated`, `AddressGenerated`, etc.
- BLoCs subscribe in constructor, unsubscribe in `close()`
- Full decoupling: emitter doesn't know consumers exist
- Cross-feature only — intra-feature communication stays within BLoC

---

## Side-Effect Channels

Two distinct channels for effects that don't belong in state:

| Channel | API | Use when |
|---|---|---|
| **Action stream** | `emitAction(XxxAction(...))` in BLoC, `ActionBlocConsumer`/`ActionBlocListener` in UI | One-shot UI effects for the **same** feature: SnackBar, navigation, focus, clipboard, dialog |
| **Event bus** | `_eventBus.emit(XxxEvent(...))` in BLoC, subscribed in another BLoC's constructor | **Cross-feature** notifications: a transaction broadcast triggers the UTXO list to refresh |

Rules:
- `emitAction` — transient, consumed once, not stored in state. Use for everything that fires-and-forgets within the current screen/feature.
- `AppEventBus.emit` — for signals that cross feature boundaries. The emitting BLoC does not know which other BLoCs listen.
- **Never** route UI effects (SnackBar, navigation) through `AppEventBus` — that couples presentation to the bus.
- **Never** route cross-feature notifications through `emitAction` — actions are scoped to one BLoC's widget subtree.
- BLoC state carries only **persistent render signals**: status enums, data lists, typed failure fields. No `Exception? exception`.

### Status enum design

Status describes *process phase*, not outcome. Baseline for simple flows:

```dart
enum XxxStatus { idle, processing }
```

Rules:
- **No `error` value.** Errors are one-time signals → `emitAction(XxxErrorOccurred(...))`, state returns to `idle`. Exception: a page-level persistent error render (e.g. "failed to load, retry") may use a typed nullable failure field (`KeysException? failure`) instead of an `error` status value — derive the error state from `state.failure != null`.
- **No redundant values.** `loaded` is the same as `idle` with data — derive from list being non-empty. `awaitingSeedConfirmation` is the same as `state.pendingHdWallet != null` — drop the status value.
- **Wizard flows** with meaningful intermediate steps (`scanning`, `scanned`, `signing`, `broadcasted`) may keep those step values — but still no `error` and no `initial`/`idle` redundancy.
- **After every error** always `emit(state.copyWith(status: XxxStatus.idle))` so the UI never gets stuck.

### Inter-event data belongs in State

Any data read in event handler B that was written in event handler A must live in `State`, not as a BLoC instance variable. Instance variables break hot-restart, make BLoC non-serialisable, and hide state from tests.

```dart
// Wrong
HdWallet? _pendingHdWallet;          // invisible to state machine, lost on restart

// Correct
state.pendingHdWallet                // visible, testable, survives re-subscription
```

---

## Repositories, DataSources, and Use Cases

- `abstract interface class` for interfaces; `Impl` suffix for implementations.
- Doc comments on all interface methods.
- **Repository** = storage contract (CRUD). No business logic. Interface in module `domain/`, implementation in module `data/`.
- **DataSource** = contract for storage or external system, **owned by the consumer module**. Interface in consumer's `domain/data_sources/`, implementation in `data/` or adapter package.
  - `WalletLocalDataSource` — in `wallet/domain/data_sources/`
  - `AddressLocalDataSource` — in `address/domain/data_sources/`
  - `BitcoinCoreRemoteDataSource` — in `wallet/domain/data_sources/`, implemented in `bitcoin_node/`
- **Use Cases** — Application layer, live in `packages/<module>/src/application/`. Orchestrate repositories, services, and data sources; produce and return domain entities.
- Every package exposes one public barrel `package:<module>/<module>.dart` and may expose an optional `package:<module>/<module>_assembly.dart`. Treat everything under `src/` as internal.

---

## Navigation

Navigator 2.0 via custom `RouterDelegate` — no third-party routing packages.

- `AppRouterDelegate` registered with `MaterialApp.router(routerDelegate: _delegate)`
- `build()` wraps `Navigator` with feature scopes
- Imperative pushes via `AppRouter` static methods
- Screens navigate directly via `AppRouter` — no callbacks up the tree

---

## Code Style

See [code-style-guide.md](./code-style-guide.md).

---

## Testing

- All Bitcoin-specific code (BIP39, derivation, coin selection, script) must have unit tests.
- RPC integration — tests against a live regtest node. Do not mock Bitcoin Core.
- Module tests organized by layer: `domain/` (pure unit), `application/` (mocked ports), `data/` (integration).

---

## Dependencies

- Exact versions: `crypto: 3.0.7`, not `^3.0.7`. Alphabetical in pubspec.yaml.
- No high-level Bitcoin wallet library — implement BIP39/BIP32/address encoding manually
  using `crypto` + `pointycastle`. Goal: demonstrate knowledge of Bitcoin standards.

---

## Process Rules

**README touch rule**: any change to a package's layer structure (subfolder add, remove, or rename under `domain/`, `application/`, or `data/`) must touch that package's `README.md` in the same PR. This is a process rule; no CI check enforces it — reviewer discipline is the barrier.

---

## Prohibited

These are hard rules. Never violate them.

- **Never** use mainnet/testnet keys or real funds
- **Never** use `!` (null assertion) operator — null-check with a local variable instead
- **Never** use `dynamic` — use `Object` or `Object?`; JSON maps = `Map<String, Object?>`
- **Never** use `print` — use `dart:developer` log
- **Never** use Cubit — BLoC only, always
- **Never** use GetIt or any service locator — constructor DI + InheritedWidget only
- **Never** expose private keys outside the data/domain layer
- **Never** use relative imports — always `package:` imports
- **Never** pass BLoC as constructor parameter to Widget — use `context.read<T>()` instead
- **Never** do `BlocProvider(create: (_) => widget.bloc)` — this hands lifecycle to provider while BLoC was created externally
- **Never** commit with analyzer warnings or infos — `flutter analyze --fatal-infos --fatal-warnings` must pass
- **Never** use `^` in dependency versions — exact versions only (e.g. `crypto: 3.0.7`)
- **Never** create private `_buildXxx` methods in widgets — extract as separate widget classes
- **Never** put repository/service implementations inside a feature directory — use module `data/`
- **Never** put entities or interfaces inside a feature directory — use module `domain/`
- **Never** log or expose mnemonic/seed/private key material in UI, logs, or error messages
- **Never** import from another feature's bloc or domain — cross-feature only via event bus or router
- **Never** import module `src/data/*` from features — use public API (barrel) only
- **Never** deep-import `package:<module>/src/*` from `lib/` or `test/` — use package barrels
- **Never** import app code from a workspace package
- **Never** create top-level `components/` for business modules
- **Never** create god-object BLoCs handling multiple flows — one BLoC per flow
