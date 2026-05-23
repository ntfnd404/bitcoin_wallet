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

### Package types

| Type | Packages | Internal structure |
|------|----------|--------------------|
| **Business** | `transaction`, `keys`, `wallet` | `domain/` + `application/` + `data/` (Clean Architecture layers) |
| **Infrastructure** | `bitcoin_node` | Organised by domain concept (`address/`, `transaction/`, `utxo/`, …) — no layer split because every file is a gateway adapter |
| **Adapter** | `rpc_client`, `storage` | Flat or minimal; no business domain |
| **UI** | `ui_kit` | By UI concern (`theme/`, `tokens/`, `typography/`) |
| **Shared** | `shared_kernel` | Flat; pure primitives shared across all BCs |

### `data/` subfolder rules (business packages only)

`data/` subfolders mirror the type of artifact they contain:

| `domain/` subfolder | `data/` subfolder | Contains |
|---------------------|-------------------|----------|
| `domain/repositories/` | `data/repositories/` | `*RepositoryImpl` + any mappers it uses |
| `domain/services/` | `data/services/` | `*ServiceImpl` + any data files it uses |
| _(no counterpart)_ | `data/data_sources/` | `*DataSource` interface **and** `*DataSourceImpl` — fully internal to the data layer |

**Rules:**
- Repository and service interfaces live in `domain/<subfolder>/`, implementations in `data/<subfolder>/`.
- **DataSource interfaces do NOT live in `domain/`** — they are an infrastructure detail owned by the data layer. Both the interface and implementation reside in `data/data_sources/`.
- A mapper (`*Mapper`) lives alongside the `*RepositoryImpl` that uses it — never in a separate `mapper/` folder.
- `crypto/` inside `keys/data/` is a private implementation detail of the crypto services; it has no corresponding `domain/crypto/` because it is never exposed as a contract.
- Infrastructure packages (`bitcoin_node`) do NOT follow this rule — they organise by domain concept, not by layer.

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

**Guiding principle:** an interface lives in the layer of its **caller**. If domain code calls it, the interface belongs to `domain/`. If only data-layer code calls it, the interface belongs to `data/`.

| | Repository | Gateway | DataSource |
|---|---|---|---|
| **What it hides** | Access to an aggregate/entity (storage of *our* data) | An external system / another bounded context (Bitcoin Core RPC, payment provider, foreign service) | Raw storage technology inside our own context (Hive, SQLite, SharedPreferences, HTTP client) |
| **Contract language** | Domain entities, aggregate semantics | Domain language of the consumer module (e.g. `createWallet(name)`, not `bitcoind.createwallet`) | Close to the storage technology, but in terms of our entities |
| **Who calls it** | Use cases (application layer) | Use cases or repositories | Only `*RepositoryImpl` / `*GatewayImpl` inside the same `data/` layer |
| **Where the interface lives** | `domain/repositories/` | `domain/gateways/` (it is an outbound port) | `data/data_sources/` (internal implementation detail) |
| **Where the implementation lives** | `data/repositories/` | Separate infra/adapter package (e.g. `bitcoin_node/`) — DIP: consumer owns the contract, adapter implements it | `data/data_sources/` (next to the interface) |
| **Reason to swap** | Different aggregate persistence strategy | Different node/provider/bounded context | Different DB or cache technology |

**Examples in this repo:**
- `WalletRepository` (interface in [wallet/domain/repositories/](../../packages/wallet/lib/src/domain/repositories/)) → `WalletRepositoryImpl` in [wallet/data/repositories/](../../packages/wallet/lib/src/data/repositories/).
- `NodeWalletGateway` (interface in [wallet/domain/gateways/](../../packages/wallet/lib/src/domain/gateways/)) → `NodeWalletGatewayImpl` in [bitcoin_node/](../../packages/bitcoin_node/lib/src/wallet/) — the adapter package depends on `wallet`, not vice versa.
- `WalletLocalDataSource` (interface + impl both in [wallet/data/data_sources/](../../packages/wallet/lib/src/data/data_sources/)) — never referenced from `domain/`.

**Mental model:** Repository = «what» (domain language, aggregate). Gateway = «where outward» (port to the outside world). DataSource = «how to store here» (repository's internal detail).

App code imports package barrels only. `package:<module>/src/*` deep imports from `lib/` or `test/` are forbidden.

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

### Naming conventions

| Artifact | Suffix | Example |
|----------|--------|---------|
| BLoC class | `Bloc` | `WalletBloc` |
| Event base | `Event` | `WalletEvent` |
| Concrete event | (past-tense verb phrase) | `WalletListRequested` |
| State class | `State` | `WalletState` |
| Status enum | `Status` | `WalletStatus` |
| Action base | `Action` | `WalletAction` |
| Concrete action | `*Action` | `WalletErrorOccurredAction` |

All concrete action classes **must** end with `Action` — symmetrically with `Bloc`, `Event`, `State`.

### Status enum values

Use `idle / processing / successful` (not `initial / loading / loaded`).
Errors are one-time signals: `emitAction(XxxFailedAction(...))` → SnackBar.
No `error` value in the status enum.
Broad `catch (e, stack)` in BLoC handlers must also `emitAction` a generic failure action (e.g. `XxxUnexpectedFailedAction`) before `addError` so the user always sees feedback.

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
- `StreamController<DomainEvent>.broadcast()` — multiple subscribers
- Typed events: `abstract base class DomainEvent` → `sealed class TransactionDomainEvent` → `TransactionBroadcasted`, `BlockMined`, etc.
- BLoCs subscribe in constructor, unsubscribe in `close()`
- Full decoupling: emitter doesn't know consumers exist
- Cross-feature only — intra-feature communication stays within BLoC

---

## Side-Effect Channels

Two distinct channels for effects that don't belong in state. One-line distinction:

> **Action = "the feature talks to its own UI."**
> **EventBus = "the feature talks to another feature, without knowing which."**

| Channel | API | Direction | Use when |
|---|---|---|---|
| **Action stream** | `emitAction(XxxAction(...))` in BLoC, `ActionBlocConsumer`/`ActionBlocListener` in UI | BLoC → UI of the **same** feature | One-shot UI effects: SnackBar, navigation, focus, clipboard, dialog |
| **Event bus** | `_eventBus.emit(XxxEvent(...))` in BLoC; `_eventBus.on<XxxEvent>().listen(...)` in another BLoC's constructor (unsubscribe in `close()`) | BLoC → **another BLoC**, cross-feature | Broadcast → refresh; cross-feature notifications |

Why both exist:
- **Action stream** keeps presentation effects out of state, so widget rebuild does not retrigger SnackBars / navigation. The action is consumed once and gone.
- **EventBus** keeps BLoCs out of each other's import graph. Emitter does not know who subscribes; subscribers do not know who emits. Coupling is only through the typed `DomainEvent` hierarchy.

Rules:
- `emitAction` — transient, consumed once, not stored in state. Use for everything that fires-and-forgets within the current screen/feature.
- `AppEventBus.emit` — for signals that cross feature boundaries. The emitting BLoC does not know which other BLoCs listen.
- **Never** route UI effects (SnackBar, navigation) through `AppEventBus` — that couples presentation to the bus and inverts dependency direction.
- **Never** route cross-feature notifications through `emitAction` — actions are scoped to one BLoC's widget subtree; another feature will never see them.
- **Never** use `BlocListener<OtherFeatureBloc, …>` across features — it couples presentation to a concrete BLoC of another feature, requires a direct import across feature boundaries, and breaks the dependency direction. Use `AppEventBus` instead.
- BLoC state carries only **persistent render signals**: status enums, data lists, typed failure fields. No `Exception? exception`.

Decision procedure for any side-effect or cross-feature interaction — three questions in order:

1. Is the effect in the UI of the **same** feature? → Action stream.
2. Do I need to notify **another** feature? → EventBus.
3. Tempted to write `BlocListener<OtherFeatureBloc, …>` in this feature? → **No.** Rewrite as EventBus subscription.

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
- **Repository** = storage contract (CRUD). No business logic. Interface in module `domain/repository/`, implementation in module `data/repository/`.
- **DataSource** = infrastructure contract for raw storage or external system. Fully internal to the data layer — both interface and implementation live in `data/data_sources/`. Never placed in `domain/`.
  - `WalletLocalDataSource` (interface + impl) — in `wallet/data/data_sources/`
  - `AddressLocalDataSource` (interface + impl) — in `address/data/data_sources/`
  - Remote data sources that cross to an adapter package declare the interface in the consumer's `data/data_sources/` and implement it in the adapter package (e.g. `bitcoin_node/`)
- **Use Cases** — Application layer, live in `packages/<module>/src/application/`. Orchestrate repositories, services, and data sources; produce and return domain entities.
- Every package exposes one public barrel `package:<module>/<module>.dart` and may expose an optional `package:<module>/<module>_assembly.dart`. Treat everything under `src/` as internal.
- **Thin use case rule** — do not create a use case that only delegates to a single repository or gateway method with no added logic. Call the repository / gateway directly. A use case is justified when it orchestrates multiple calls, translates between bounded contexts, enforces a domain rule, or handles scenario-specific exceptions.

---

## Error Handling

### Layer responsibilities

Each layer handles only the errors that belong to its contract:

- **Gateway / DataSource** (`*GatewayImpl`) — translates external failures (RPC, network, parse) into bounded-context exceptions. Uses `catch (_, stack)` + `Error.throwWithStackTrace`. No domain logic inside the catch.
- **Use Case** — catches only exceptions that are part of the use-case scenario: cross-BC translation, algorithm fallbacks, security sanitization. Does NOT re-wrap exceptions already translated by the gateway/repository beneath it. Does NOT use broad `catch (e, stack)` unless justified by all four criteria (see SB-5).
- **BLoC / Controller** — catches bounded-context domain exceptions for UI feedback (`on XxxException catch (e) → emitAction`). Unexpected errors go to `addError` for the zone handler. Always `emitAction` a generic failure action **before** `addError` so the user sees feedback even if the BLoC closes.
- **Domain Service** — no `try/catch` except expected algorithm branches (e.g. `InsufficientFundsException` inside a coin-selection loop).

### `rethrow` vs `Error.throwWithStackTrace`

- `rethrow` — re-throws the **same** exception object. Use when the catch block adds no translation and the exception type must stay unchanged.
- `Error.throwWithStackTrace(newException, stack)` — creates a **new** exception while preserving the original stack trace. Use when translating an external exception into a bounded-context one at a layer boundary.

```dart
// ✅ rethrow — same exception, same type
on TransactionException {
  rethrow;
}

// ✅ throwWithStackTrace — new domain exception, original stack preserved
} catch (_, stack) {
  Error.throwWithStackTrace(const TransactionFetchException(), stack);
}

// ❌ throw without preserving stack — stack trace is lost
} catch (_) {
  throw const TransactionFetchException();
}
```

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

### Widget file rules

- **One public widget class per file.** Never put multiple widget classes in one file.
- **No private widgets** (`_MyWidget`). All widgets are public — private widgets cannot be tested independently.
- Reusable widgets live in `lib/feature/<feature>/view/widget/`. Each widget has its own file named after the class (`broadcast_result.dart` → `BroadcastResult`).
- `_State` classes (the `State<T>` implementation) are the only acceptable private class in a screen file — they belong alongside their `StatefulWidget`.

---

## Testing

- All Bitcoin-specific code (BIP39, derivation, coin selection, script) must have unit tests.
- RPC integration — tests against a live regtest node. Do not mock Bitcoin Core.
- Module tests organized by layer: `domain/` (pure unit), `application/` (mocked ports), `data/` (integration).

### Test Double Placement

Test helpers (fakes, mocks, stubs) must **never** be defined inline inside a test file.
Each test double lives in its own file, named after the class it contains.

**Folder structure** — place doubles alongside the test file in a subfolder named by role:
```
test/feature/<feature>/
  <test_name>_test.dart
  fakes/
    fake_<name>.dart      ← Fake: working in-memory implementation
    fake_slow_<name>.dart
  mocks/
    mock_<name>.dart      ← Mock: created via mocktail/mockito, verifies interactions
```

No `helpers/` folder. Use `fakes/` or `mocks/` only.

**Naming taxonomy** (xUnit roles):
- `Fake*` — working simplified implementation (e.g. in-memory repository)
- `Mock*` — created via mocktail/mockito, verifies call expectations
- `Stub*` — minimal concrete implementation that returns fixed values (no expectations)
- `Spy*` — records calls for later assertion without blocking them

### TDD principle — test through interfaces, not implementations

Unit-test consumers through interface fakes/mocks, not concrete `*Impl` classes.
Infrastructure implementations (`*GatewayImpl`, `*RepositoryImpl`) are tested via
integration tests against the real external system, not unit-tested with mocked internals.

```dart
// ❌ Wrong — tests GatewayImpl by mocking its internal http.Client
class _MockHttpClient extends Mock implements http.Client {}
final gateway = BlockGenerationGatewayImpl(rpcClient: BitcoinRpcClient(..., client: mock));

// ✅ Correct — test the BLoC through FakeBlockGenerationGateway
final bloc = RegtestMiningBloc(blockGenerationGateway: FakeBlockGenerationGateway());
```

Rule: if you are mocking a dependency **of the impl** (not of the interface the BLoC depends on), you are testing implementation details — move that to integration tests or remove it.

### mocktail usage rules

- Use mocktail to mock `abstract class` or `abstract interface class` only — **never** `final class`.
- Declaration: `class MockFoo extends Mock implements FooInterface {}`
- Place in `test/<feature>/mocks/mock_foo.dart`.
- Use `when()` / `verify()` only when interaction verification is the test goal.
- Prefer `Fake*` over `Mock*` when you don't need to assert call counts or argument capture.

```dart
// ✅ Correct — mocking an interface
abstract interface class BlockGenerationGateway { ... }
class MockBlockGenerationGateway extends Mock implements BlockGenerationGateway {}

// ❌ Wrong — cannot mock a final class with mocktail
final class BitcoinRpcClient { ... }
class MockBitcoinRpcClient extends Mock implements BitcoinRpcClient {} // compile error
```

**BLoC state enum standard** — use `idle / processing / successful` (not `initial / loading / loaded`).
Errors are one-time signals via `emitAction(XxxFailed(...))` — never an `error` value in the status enum.

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
- **Never** use an initialiser list for simple field assignment when an initialising formal (`this._field`) suffices — use `dart fix --apply` to enforce

---

## Architectural Import Boundaries

Three import boundaries are enforced by code review. DCM `avoid-banned-imports`
and `restrict_imports` require a paid subscription — boundaries are verified manually.

| Boundary | Guarded scope | Forbidden import |
|----------|--------------|-----------------|
| SB-7: `transaction` ↛ `keys` | `packages/transaction/lib/` | `package:keys/` |
| `keys` ↛ `transaction`/`wallet` | `packages/keys/lib/` | `package:transaction/`, `package:wallet/` |
| View layer ↛ gateway/repository | `lib/feature/**/view/**` | any URI containing `/gateway/` or `/repository/` |

---

## Signing Boundary

The signing boundary is the set of rules governing how seed material, private keys,
and cryptographic secrets move through the `keys` bounded context. Violations are
treated as Critical-lane defects.

### Rule SB-1 — Secrets do not cross the `keys` BC boundary

Mnemonic words and raw private-key bytes (`Uint8List`) must never appear in:
- method parameters or return values on any public API (barrel exports of `keys.dart`)
- exception messages, `toString()` output, or log calls
- cross-package DTOs or value objects

The only crossing is the signed transaction hex string, which is the intentional
output of `SignTransactionUseCase`.

### Rule SB-2 — `keys.SigningInput` is internal

`keys.SigningInput` carries a raw 32-byte private key. It is NOT exported from
`package:keys/keys.dart`. It is an application-internal DTO used only by
`TransactionSigningService`, which is also internal to `keys`. External code must
never reference this type.

### Rule SB-3 — `toString` overrides on sensitive types are mandatory

Any type that carries, or appears structurally adjacent to, sensitive material MUST
override `toString` before being committed. The override must either:
(a) redact all sensitive fields — `'TypeName(<redacted>)'`, or
(b) enumerate all safe fields explicitly and exclude sensitive ones.

Relying on the Dart default `Object.toString()` is forbidden for these types even
though the default is currently safe.

Affected types:
- `Mnemonic` → `'Mnemonic(<redacted>)'`
- `keys.SigningInput` → shows `txid`, `vout`, `amountSat`; redacts `privateKey` and `publicKey`

### Rule SB-4 — `KeysException` subtypes must remain zero-field

No subtype of `KeysException` may carry wallet identifiers, key material, seed
phrases, or derivation paths. All subtypes must be zero-arg with a fixed string
`toString`. This invariant is machine-checked by `packages/keys/test/keys_exception_test.dart`.

### Rule SB-5 — Broad catch in signing use cases is permitted by security policy

The signing use case (`SignTransactionUseCase`) uses a broad `catch (_, stack)` to
wrap all unexpected errors from the signing service as `KeysSigningException`. This
is a deliberate security-first policy justified by all four criteria:

- C1 (change abstraction): translates internal crypto exception vocabulary to the
  `keys` domain language.
- C2 (hide secrets): the caught exception message or chained cause may carry key
  material; discarding it via `_` is the only safe option.
- C3 (add context): the original stack trace is preserved via
  `Error.throwWithStackTrace` for debugging without exposing the message.
- C4 (can recover): the caller can distinguish `KeysSeedNotFoundException`,
  `KeysDerivationException`, and `KeysSigningException` and act accordingly.

Consequence: `ArgumentError` from signing-service misuse is also mapped to
`KeysSigningException`. This is intentional — programmer errors in the crypto stack
are sanitized the same way as runtime errors because distinguishing them at runtime
would require inspecting exception messages, which violates C2.

### Rule SB-6 — Key zeroing is a known limitation

Raw private-key `Uint8List` values constructed inside `SignTransactionUseCase` become
GC-eligible immediately after `_signing.signP2wpkh` returns. No explicit zeroing is
performed because the Dart VM JIT compiler does not guarantee physical memory zeroing.
This is an acknowledged limitation for a regtest educational project. Do not add
zeroing code without a Dart VM–specific analysis confirming it is effective.

### Rule SB-7 — `transaction` must not depend on `keys`

The `transaction` package does not declare `keys` as a dependency. `HdTransactionSigner`
(the crossing-point adapter) lives in the app layer (`lib/core/adapters/`) precisely to
avoid this coupling. The broad `on Exception catch` in `SendHdTransactionUseCase`
(line 63 of `send_hd_transaction_use_case.dart`) is justified by this dependency
direction rule: `KeysException` subtypes arrive as opaque `Exception` objects at the
`transaction` boundary. This is a deliberate structural gap, not a coding error.
