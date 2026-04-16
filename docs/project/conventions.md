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

Feature-first app + business modules as packages + layered modules + hard architecture gate. See [architecture.md](./architecture.md) for full details.

### Layers (Clean + Hexagonal)

```
Presentation (features in app/) → Application/Domain (modules in packages/) ← Infrastructure (data/ in modules)
```

- **Feature** — Flutter UI + BLoC per flow. `lib/feature/`. Depends on module public API only.
- **Module domain** — entities + repository/service/data source interfaces. Pure Dart. `packages/<module>/src/domain/`.
- **Module application** — use cases, query APIs. `packages/<module>/src/application/`.
- **Module data** — implementations. `packages/<module>/src/data/`.
- **Infrastructure** — `bitcoin_node`, `platform_storage`, `observability`: each wraps one external system.
- **Design system** — `design_system`: Flutter-only, no domain knowledge.
- **Shared kernel** — `shared_kernel`: tiny shared primitives (BitcoinNetwork, Failure, Result).

See [architecture.md — Project Structure](./architecture.md#project-structure) for the full folder tree.

### Package dependency graph

```
wallet         → shared_kernel, keys
address        → shared_kernel, keys
keys           → shared_kernel
bitcoin_node   → wallet, address (implements their DataSource interfaces)
platform_storage → (nothing business)
observability  → (nothing business)
design_system  → Flutter SDK
shared_kernel  → (nothing)
```

### Package type rules

| Type | Packages | Rule |
|------|----------|------|
| **shared** | `shared_kernel` | Tiny shared primitives. Pure Dart. Zero business deps. |
| **business** | `wallet`, `address`, `keys` | domain/ + application/ + data/. Own entities, use cases, implementations. |
| **infra** | `bitcoin_node`, `platform_storage`, `observability` | Wraps one external system. No domain knowledge. |
| **ui** | `design_system` | Design system only. No domain knowledge. |

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

### Ownership rules

- Each entity has **one owner module** — no shared ownership.
- Other modules use: Id, small value objects, public query APIs (ReadApi).
- See [architecture.md](./architecture.md) for full ownership table.

### DataSource ownership

- DataSource interfaces (contracts for storage and external systems) are **owned by the consumer module**, not the adapter.
- Example: `BitcoinCoreRemoteDataSource` lives in `wallet/domain/data_sources/`, not in `bitcoin_node/`.
- `bitcoin_node` implements `BitcoinCoreRemoteDataSource`.
- This is DIP: high-level module defines the contract, low-level module implements it.

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
final class WalletListState {
  const WalletListState({
    this.wallets = const [],
    this.status = WalletListStatus.initial,
    this.errorMessage,
  });

  final List<Wallet> wallets;
  final WalletListStatus status;
  final String? errorMessage;

  WalletListState copyWith({...});
}

enum WalletListStatus { initial, loading, loaded, error }
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

## Repositories, DataSources, and Use Cases

- `abstract interface class` for interfaces; `Impl` suffix for implementations.
- Doc comments on all interface methods.
- **Repository** = storage contract (CRUD). No business logic. Interface in module `domain/`, implementation in module `data/`.
- **DataSource** = contract for storage or external system, **owned by the consumer module**. Interface in consumer's `domain/data_sources/`, implementation in `data/` or adapter package.
  - `WalletLocalDataSource` — in `wallet/domain/data_sources/`
  - `AddressLocalDataSource` — in `address/domain/data_sources/`
  - `BitcoinCoreRemoteDataSource` — in `wallet/domain/data_sources/`, implemented in `bitcoin_node/`
- **Use Cases** — Application layer, live in `packages/<module>/src/application/`. Orchestrate repositories, services, and data sources; produce and return domain entities.

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
- **Never** create god-object BLoCs handling multiple flows — one BLoC per flow
