# Target Architecture

Feature-first app + business modules as packages + layered modules + hard architecture gate.

---

## Philosophy

This is a hybrid approach, not a single pattern:

- **Feature Architecture** — UI/flow ownership per screen
- **Clean Architecture** — dependency rule (always inward)
- **DDD** — bounded context ownership, ubiquitous language
- **Hexagonal** — ports owned by consumers, adapters implement
- **Modular** — package isolation, explicit public APIs
- **Hard gate** — architecture lint, import policy enforcement

---

## Dependency Graph

```
                    ┌─────────────┐
                    │ shared_     │
                    │ kernel      │
                    │ (nothing)   │
                    └──────▲──────┘
                     ╱     │      ╲
                   ╱       │        ╲
          ┌──────┘    ┌────┘    ┌────┘───┐
          │           │         │        │
    ┌──────────┐ ┌──────────┐ ┌──────┐   │
    │  wallet  │ │ address  │ │ keys │   │
    │          │ │          │ │      │   │
    │ domain/  │ │ domain/  │ │domain│   │
    │ app/     │ │ app/     │ │data/ │   │
    │ data/    │ │ data/    │ │      │   │
    └────┬─────┘ └────┬─────┘ └──▲───┘   │
         │            │          │        │
         │   ┌────────┘          │        │
         ├───┼───────────────────┘        │
         │   │                            │
         │   │  implements data sources    │
         ▼   ▼                            │
    ┌──────────────┐                      │
    │ bitcoin_node │──────────────────────┘
    │              │
    │ BitcoinCore  │ → platform_storage
    │ RemoteData   │ → observability
    │ SourceImpl   │
    └──────────────┘

    ─────► depends on (imports)
    wallet ──► keys ──► shared_kernel
    address ──► keys ──► shared_kernel
    bitcoin_node ──► wallet (for BitcoinCoreRemoteDataSource)
    bitcoin_node ──► address (for BitcoinCoreRemoteDataSource)
```

---

## Project Structure

```
app/
  lib/
    app/
      bootstrap/                       ← main() + init logic
      root_app.dart                    ← App widget
    core/
      di/                              ← AppDependencies, AppScope
      routing/                         ← AppRouterDelegate, AppRouter
      event_bus/                       ← AppEventBus, sealed AppEvent
      common/                          ← shared extensions/utils
    feature/
      wallet/
        list/
          di/                          ← WalletListScope
          bloc/                        ← WalletListBloc
          presentation/                ← WalletListScreen, WalletCard
        setup/
          di/                          ← WalletSetupScope
          bloc/                        ← WalletSetupBloc
          presentation/                ← CreateWalletScreen, SeedPhraseScreen, RestoreWalletScreen
        detail/
          di/                          ← WalletDetailScope
          bloc/                        ← WalletDetailBloc
          presentation/                ← WalletDetailScreen
        shared/                        ← widgets shared across wallet flows
      address/
        generate/
          di/                          ← AddressGenerateScope
          bloc/                        ← AddressGenerateBloc
          presentation/                ← AddressScreen
        shared/

packages/
  shared_kernel/                       ← BitcoinNetwork, Failure, Result, Amount
  design_system/                       ← tokens, typography, theme, widgets
  platform_storage/                    ← SecureStorage interface + impl
  observability/                       ← logging, error tracking
  bitcoin_node/                        ← RPC client + adapter implementations

  wallet/
    lib/
      wallet.dart                      ← barrel (public API only)
      wallet_assembly.dart             ← module DI factory
      src/
        domain/
          entity/
            wallet.dart
            wallet_type.dart
          repository/
            wallet_repository.dart     ← interface
          data_sources/
            wallet_local_data_source.dart        ← interface
            bitcoin_core_remote_data_source.dart  ← interface (consumer-owned)
        application/
          create_node_wallet.dart
          create_hd_wallet.dart
          restore_hd_wallet.dart
          wallet_read_api.dart         ← query API for other modules
        data/
          wallet_repository_impl.dart
          wallet_local_store.dart
          wallet_mapper.dart

  address/
    lib/
      address.dart
      address_assembly.dart
      src/
        domain/
          entity/
            address.dart
            address_type.dart
          repository/
            address_repository.dart
          data_sources/
            address_local_data_source.dart
        application/
          generate_address.dart
          hd_address_strategy.dart
          node_address_strategy.dart
          address_read_api.dart
        data/
          address_repository_impl.dart
          address_local_store.dart
          address_mapper.dart

  keys/
    lib/
      keys.dart
      keys_assembly.dart
      src/
        domain/
          entity/
            mnemonic.dart
          repository/
            seed_repository.dart
          service/
            bip39_service.dart
            key_derivation_service.dart
        data/
          bip39_service_impl.dart
          key_derivation_service_impl.dart
          seed_repository_impl.dart
          bip32/
          encoding/
          bip39_wordlist.dart
```

---

## Ownership Table

| Module | Owns | Exposes to Others |
|--------|------|-------------------|
| **wallet** | Wallet, WalletType, WalletRepository, WalletLocalDataSource, BitcoinCoreRemoteDataSource (wallet part) | WalletId, WalletReadApi |
| **address** | Address, AddressType, AddressRepository, AddressLocalDataSource | AddressId, AddressReadApi |
| **keys** | Mnemonic, SeedRepository, Bip39Service, KeyDerivationService | All domain types + services |
| **bitcoin_node** | BitcoinRpcClient, BitcoinCoreRemoteDataSourceImpl | DataSource implementations only |
| **shared_kernel** | BitcoinNetwork, Failure, Result, Amount | Everything (shared primitives) |
| **platform_storage** | SecureStorage, SecureStorageImpl | Storage interface + impl |
| **observability** | Logger, ErrorTracker | Logging/tracking API |
| **design_system** | Tokens, Typography, Theme, Widgets | UI components |

### Ownership rules

- Each entity has **one owner** — no shared ownership
- Other modules use: Id, small value objects, public query APIs
- If module A needs entity from module B → import B's public lightweight type, not the full entity or repository

---

## What Lives Where

### app/lib/feature/*

- Screens, widgets
- BLoC / state / events (per-flow)
- Scopes (DI composition root per flow)
- Navigation
- Feature-local orchestration (optional application/ layer when composing multiple module APIs)

### packages/\<module\>/src/domain/

- Entities, value objects
- Policies, invariants
- Repository contracts (interfaces)
- DataSource contracts (interfaces, owned by this module)
- Domain services (pure, no IO)

### packages/\<module\>/src/application/

- Shared use cases of this module
- Query/command APIs (ReadApi for other modules)
- Orchestration not tied to a single screen

### packages/\<module\>/src/data/

- Repository implementations
- Remote/local datasource
- DTO/mapper
- DataSource implementations (bitcoin_node implements consumer-owned DataSource interfaces)

---

## Module Internal Structure

Each business module follows identical layered structure:

```
packages/<module>/
├── lib/
│   ├── <module>.dart            ← barrel: public API only
│   ├── <module>_assembly.dart   ← module DI factory
│   └── src/
│       ├── domain/              ← PURE: no IO, no frameworks
│       ├── application/         ← ORCHESTRATION: uses domain + ports
│       └── data/                ← INFRASTRUCTURE: implements domain interfaces
└── test/
    ├── domain/                  ← unit tests (pure, fast)
    ├── application/             ← unit tests with mocked ports
    └── data/                    ← integration tests
```

Layer rules within a module:

```
domain/      ← depends on: shared_kernel ONLY
application/ ← depends on: own domain, other modules' public API (lightweight, rare)
data/        ← depends on: own domain, platform_storage, observability
```

---

## Feature Internal Structure

Feature = Bounded Context. Flow = screen/scenario within BC.

Each flow has its own BLoC, scope, and presentation:

```
app/lib/feature/<bc>/
├── <flow>/
│   ├── di/             ← Scope: creates BLoC in didChangeDependencies + _initialized
│   ├── bloc/           ← BLoC + events + state for this flow only
│   └── presentation/   ← screens + widgets for this flow
└── shared/             ← widgets shared across flows of this BC
```

Feature rules:
- Each flow has its **own BLoC** — no god-object BLoC
- BLoC calls module public API (use cases) directly
- Optional feature-local `application/` when orchestrating multiple module APIs for one screen
- **Scope** = assembles dependencies in `didChangeDependencies`, exposes factory (static method + InheritedWidget). Does NOT hold BLoC instances
- **BlocProvider(create: ...)** = placed low in tree near screen. Creates BLoC via Scope factory. Auto-disposes
- **Never** use `BlocProvider.value` — always `BlocProvider(create: ...)`
- Cross-flow communication via `AppEventBus`, not BLoC-to-BLoC subscription

---

## How Feature Connects to Module

```
app/feature/wallet/setup/presentation/
  → WalletSetupBloc
  → WalletSetupScope

WalletSetupBloc
  → wallet public use cases (CreateNodeWallet, CreateHdWallet, RestoreHdWallet)
  → keys public API (Bip39Service for mnemonic validation)

If feature-local application needed:
feature/wallet/setup/application/
  → ValidateAndCreate (composes wallet + keys APIs for setup flow)
```

UI flow lives in feature. Reusable business logic lives in module package.

---

## Import Policy

### Allowed

```
feature/*              → module public API (barrel)
feature/*              → design_system
feature/*              → observability
feature/*              → core/event_bus
feature/*              → feature-local application
module/application     → own domain
module/data            → own domain
module/data            → platform_storage, observability
module/application     → other module public API (lightweight types only, rare)
bitcoin_node           → module/domain (DataSource interfaces to implement)
```

### Forbidden

```
feature/*              → module/src/data/* (deep import)
feature/*              → other feature/bloc or feature/domain
module/data            → other module/data
module/domain          → feature/*
module/domain          → other module/data
module/domain          → design_system
shared_kernel          → business modules
bitcoin_node           → module/src/* (deep import, only public DataSource interfaces)
```

---

## Avoiding Cycles Between Modules

Modules form a **DAG**, never a cycle.

```
keys           → shared_kernel
wallet         → shared_kernel, keys
address        → shared_kernel, keys
bitcoin_node   → wallet, address (implements their ports)
```

If a cycle appears (e.g., wallet ↔ address):
- Extract shared contract into a separate small module
- Or replace direct dependency with query API / event / id reference

---

## Event Bus

```dart
// core/event_bus/app_event.dart
sealed class AppEvent {}
final class WalletCreated extends AppEvent { final String walletId; }
final class WalletDeleted extends AppEvent { final String walletId; }
final class SeedStored extends AppEvent { final String walletId; }
final class AddressGenerated extends AppEvent { final String walletId; }

// core/event_bus/app_event_bus.dart
final class AppEventBus {
  final _controller = StreamController<AppEvent>.broadcast();
  Stream<AppEvent> get stream => _controller.stream;
  void emit(AppEvent event) => _controller.add(event);
  void dispose() => _controller.close();
}
```

- Lives in `core/event_bus/` — no business module owns it
- `AppEventBus` created in bootstrap, provided via `AppScope`
- BLoCs subscribe in constructor, unsubscribe in `close()`
- Full decoupling: emitter doesn't know consumers exist

---

## DI / Bootstrap Graph

```
main()
  → AppBootstrap
    → BitcoinRpcClient           (infra)
    → SecureStorageImpl          (infra)
    → AppEventBus                (core)

    → KeysAssembly               (keys module)
      → Bip39ServiceImpl
      → KeyDerivationServiceImpl
      → SeedRepositoryImpl

    → WalletAssembly             (wallet module)
      → WalletRepositoryImpl
      → CreateNodeWallet, CreateHd, RestoreHd
      → WalletReadApi

    → AddressAssembly            (address module)
      → AddressRepositoryImpl
      → GenerateAddress (+ strategies)
      → AddressReadApi

    → BitcoinCoreRemoteDataSourceImpl  (bitcoin_node, implements BitcoinCoreRemoteDataSource)

    → AppDependencies            (container)
    → RootApp
```

Each Assembly creates: data/ implementations, application/ services, public module API.

Feature Scopes assemble dependencies and expose BLoC **factory** (static method + InheritedWidget).
`BlocProvider(create: Scope.newBloc(context))` placed low in tree near screen — auto-disposes.

---

## Key Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| DataSource interfaces owned by consumers, not adapter | DIP: high-level defines contract, low-level implements. ISP: each module gets exactly the interface it needs |
| Mnemonic in keys, not wallet | Information Expert: crypto/key-management context owns crypto primitives |
| Strategies in application, not domain | Strategies do IO (call services, repositories) — domain must stay pure |
| Per-flow BLoC, not per-feature | SRP: one BLoC handles one flow. Prevents god-object accumulation |
| Event bus for cross-feature | Full decoupling: emitter doesn't know consumers exist |
| Address as separate module | Independent lifecycle: receive, gap tracking, UTXO, labeling |
| No Event Sourcing / CQRS | Mobile client over Bitcoin Core's ledger — Core already does ES for us |
| No formal Domain Events | BLoC is already event-driven; AppEventBus covers cross-feature |
| Per-module packages from day one | Scalable architecture from the start, not deferred |
| Assembly per module | Each module owns its DI, not a monolithic builder |
| Scope = factory, BlocProvider low | Scope assembles deps and exposes factory. BlocProvider(create:) near screen auto-disposes. Never BlocProvider.value |

---

## What Goes in shared_kernel

Only very small shared primitives:

- BitcoinNetwork
- Failure / Result
- Amount / Money
- DateRange
- PageRequest / PageResult

**Never** put in shared_kernel: large entities, module repositories, use cases, "everything shared just in case."
