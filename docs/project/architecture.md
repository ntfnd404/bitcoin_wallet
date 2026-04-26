# Architecture

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
                             ┌───────────────┐
                             │ shared_kernel │
                             └───────┬───────┘
          ┌────────────┬─────────────┼─────────────┬───────────────┐
          ▼            ▼             ▼             ▼               ▼
       ┌──────┐   ┌─────────┐   ┌────────┐    ┌─────────┐   ┌─────────────┐
       │ keys │   │ storage │   │ wallet │    │ address │   │ transaction │
       └───┬──┘   └─────────┘   └────┬───┘    └────┬────┘   └──────┬──────┘
           │                         │             │               │
           └─────────────────────────┘             │               │
                                                   └───────┬───────┘
                                                           ▼
        ┌────────────┐                        ┌───────────────────────────┐
        │ rpc_client │───────────────────────►│      bitcoin_node         │
        └────────────┘                        │ (consumer of all modules) │
                                              └───────────────────────────┘

ui_kit — no workspace dependencies (Flutter SDK only)
```

Arrow direction: A ──► B means A depends on B.

Real edges (derived from `pubspec.yaml`):

| Package | Workspace dependencies |
|---------|------------------------|
| `shared_kernel` | — |
| `rpc_client` | — |
| `ui_kit` | — |
| `keys` | `shared_kernel` |
| `storage` | `shared_kernel` |
| `wallet` | `keys`, `shared_kernel` |
| `address` | `keys`, `shared_kernel`, `wallet` |
| `transaction` | `shared_kernel`, `address` |
| `bitcoin_node` | `address`, `rpc_client`, `shared_kernel`, `transaction`, `wallet` |

App (`lib/`) depends on all nine workspace packages.

---

## Project Structure

```
app/
  lib/
    app.dart                               ← App widget
    core/
      constants/                           ← AppConstants (network, host, port)
      di/                                  ← AppDependencies, AppDependenciesBuilder, AppScope
      routing/                             ← AppRouterDelegate, AppRouter
    feature/
      wallet/
        di/                                ← WalletScope
        bloc/                              ← WalletBloc, WalletEvent, WalletState
        view/screen/
          list/                            ← WalletListScreen
          setup/                           ← CreateWalletScreen, SeedPhraseScreen, RestoreWalletScreen
          detail/                          ← WalletDetailScreen
      address/
        di/                                ← AddressScope
        bloc/                              ← AddressBloc, AddressEvent, AddressState
        view/widget/                       ← AddressScreen, AddressTypeSection

packages/
  shared_kernel/                           ← BitcoinNetwork, AddressType, SecureStorage
  ui_kit/                                  ← UI components (placeholder)
  storage/                                 ← SecureStorageImpl (Flutter, flutter_secure_storage)
  rpc_client/                              ← BitcoinRpcClient (JSON-RPC over HTTP)

  bitcoin_node/
    lib/
      bitcoin_node.dart                    ← barrel (8 *Impl exports)
      src/
        wallet/
          wallet_remote_data_source_impl.dart
        address/
          address_remote_data_source_impl.dart
          address_type_rpc.dart
        transaction/
          broadcast_data_source_impl.dart
          node_transaction_data_source_impl.dart
          transaction_remote_data_source_impl.dart
        utxo/
          utxo_remote_data_source_impl.dart
          utxo_scan_data_source_impl.dart
        block/
          block_generation_data_source_impl.dart

  keys/
    lib/
      keys.dart                            ← barrel (public API only)
      keys_assembly.dart                   ← module DI factory
      src/
        domain/
          entity/
            mnemonic.dart
            derived_address.dart            ← value object (breaks keys↔address cycle)
          repository/
            seed_repository.dart
          service/
            bip39_service.dart
            key_derivation_service.dart
        data/
          bip39_service_impl.dart
          bip39_wordlist.dart
          key_derivation_service_impl.dart
          seed_repository_impl.dart
          crypto/
            base58.dart
            bech32.dart
            bip32.dart
            extended_key.dart
            hash_utils.dart
    test/
      bip39_service_impl_test.dart
      key_derivation_service_impl_test.dart
      seed_repository_impl_test.dart

  wallet/
    lib/
      wallet.dart                          ← barrel (public API only)
      wallet_assembly.dart                 ← module DI factory
      src/
        domain/
          entity/
            wallet.dart
          repository/
            wallet_repository.dart
          data_sources/
            wallet_local_data_source.dart
            wallet_remote_data_source.dart  ← ISP interface (createWallet only)
        application/
          hd/
            create_hd_wallet_use_case.dart
            restore_hd_wallet_use_case.dart
          node/
            create_node_wallet_use_case.dart
        data/
          wallet_repository_impl.dart
          wallet_local_data_source_impl.dart
          wallet_mapper.dart

  address/
    lib/
      address.dart                         ← barrel (public API only)
      address_assembly.dart                ← module DI factory
      src/
        domain/
          entity/
            address.dart
          repository/
            address_repository.dart
          data_sources/
            address_local_data_source.dart
            address_remote_data_source.dart ← ISP interface (generateAddress only)
        application/
          generate_address_use_case.dart
          address_generation_strategy.dart
          hd/
            hd_address_generation_strategy.dart
          node/
            node_address_generation_strategy.dart
        data/
          address_repository_impl.dart
          address_local_data_source_impl.dart
          address_mapper.dart

  transaction/
    lib/
      transaction.dart                     ← barrel (public API only)
      transaction_assembly.dart            ← module DI factory
      src/
        domain/
          entity/                          ← transaction entities, UTXO domain types
          data_sources/
            hd_address_data_source.dart    ← returns List<Address>; bridges address + transaction
            transaction_remote_data_source.dart
            utxo_remote_data_source.dart
            utxo_scan_data_source.dart
            broadcast_data_source.dart
            node_transaction_data_source.dart
            block_generation_data_source.dart
          repository/
          service/
          value_object/
        application/
          hd/
            prepare_hd_send_use_case.dart
            send_hd_transaction_use_case.dart
            hd_send_preparation.dart
          node/
            prepare_node_send_use_case.dart
            send_node_transaction_use_case.dart
            node_send_preparation.dart
          broadcast_transaction_use_case.dart
          get_transaction_detail_use_case.dart
          get_transactions_use_case.dart
          get_utxos_use_case.dart
          scan_utxos_use_case.dart
        data/
```

---

## Ownership Table

| Module | Owns | Exposes to Others |
|--------|------|-------------------|
| **shared_kernel** | BitcoinNetwork, AddressType, SecureStorage | Everything (shared primitives + contracts) |
| **keys** | Mnemonic, DerivedAddress, SeedRepository, Bip39Service, KeyDerivationService | All domain types + services |
| **wallet** | Wallet, HdWallet, NodeWallet, HdWalletRepository, NodeWalletRepository, WalletRemoteDataSource | Entities, repository, use cases |
| **address** | Address, AddressRepository, AddressLocalDataSource, AddressRemoteDataSource | Entities, repository, use case, strategies |
| **transaction** | HD/Node transaction use cases, UTXO domain types, data-source contracts | TransactionAssembly, use cases, data-source interfaces |
| **bitcoin_node** | WalletRemoteDataSourceImpl, AddressRemoteDataSourceImpl, TransactionRemoteDataSourceImpl, UtxoRemoteDataSourceImpl, UtxoScanDataSourceImpl, BroadcastDataSourceImpl, NodeTransactionDataSourceImpl, BlockGenerationDataSourceImpl | DataSource implementations only |
| **storage** | SecureStorageImpl | Storage implementation |
| **rpc_client** | BitcoinRpcClient | RPC client |
| **ui_kit** | UI components | Shared widgets |

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
- Feature-local orchestration (optional application/ layer when composing multiple module APIs for one screen)

### packages/\<module\>/src/domain/

- Entities, value objects
- Policies, invariants
- Repository contracts (interfaces)
- DataSource contracts (interfaces, owned by this module)
- Domain services (pure, no IO)

### packages/\<module\>/src/application/

- Shared use cases of this module
- Orchestration not tied to a single screen

### packages/\<module\>/src/data/

- Repository implementations
- Remote/local datasource implementations
- Serializers (encode/decode between entity and Map)
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
```

Layer rules within a module:

```
domain/      ← depends on: shared_kernel ONLY
application/ ← depends on: own domain, other modules' public API (lightweight types only, rare)
data/        ← depends on: own domain, shared_kernel (for SecureStorage)
```

---

## HD/Node Trust-Model Subfolder Split

`packages/wallet`, `packages/address`, and `packages/transaction` each split their `application/` layer into `hd/` and `node/` subfolders (introduced in Phase 3 of BW-0005).

- Files under `application/hd/` serve HD (non-custodial) wallets; files under `application/node/` serve Node (custodial) wallets.
- Cross-trust imports within the same package are forbidden: `hd/` files must not import from `node/` and vice versa.
- Shared orchestrators (e.g. `GenerateAddressUseCase`, `ScanUtxosUseCase`) remain at the `application/` root when they serve both trust models.
- Rationale and decision record: `docs/project/adr/ADR-002-trust-model-subfolder-split.md`.

---

## ISP: Interface Segregation for Remote Data Sources

The original monolithic `BitcoinCoreRemoteDataSource` was split into focused, consumer-owned interfaces:

| Interface | Package |
|-----------|---------|
| `WalletRemoteDataSource` | wallet |
| `AddressRemoteDataSource` | address |
| `AddressLocalDataSource` | address |
| `HdAddressDataSource` | transaction (returns `List<Address>` since Phase 2) |
| `TransactionRemoteDataSource` | transaction |
| `UtxoRemoteDataSource` | transaction |
| `UtxoScanDataSource` | transaction |
| `BroadcastDataSource` | transaction |
| `NodeTransactionDataSource` | transaction |
| `BlockGenerationDataSource` | transaction |

Each interface is owned by its consumer module (DIP). The `bitcoin_node` package provides implementations for all of them.

---

## DerivedAddress: Breaking the keys↔address Cycle

`keys` cannot depend on `address` (would create a cycle). `KeyDerivationService.deriveAddress()` returns `DerivedAddress` — a lightweight value object in keys:

```dart
final class DerivedAddress {
  final String value;
  final AddressType type;
  final String derivationPath;
}
```

`HdAddressGenerationStrategy` (in address package) constructs the full `Address` entity from `DerivedAddress` + wallet context.

---

## Import Policy

### Allowed

```
feature/*              → module public API (barrel)
feature/*              → ui_kit
feature/*              → core/*
module/application     → own domain
module/data            → own domain
module/data            → shared_kernel (for SecureStorage)
module/application     → other module public API (lightweight types only, rare)
bitcoin_node           → module/domain (DataSource interfaces to implement)
```

### Forbidden

```
feature/*              → module/src/* (deep import)
feature/*              → other feature/bloc or feature/domain
module/data            → other module/data
module/domain          → feature/*
module/domain          → other module/data
shared_kernel          → business modules
application/hd/        → application/node/ (same package, cross-trust)
application/node/      → application/hd/  (same package, cross-trust)
```

---

## Avoiding Cycles Between Modules

Modules form a **DAG**, never a cycle.

```
shared_kernel  → (none)
rpc_client     → (none)
keys           → shared_kernel
storage        → shared_kernel
wallet         → shared_kernel, keys
address        → shared_kernel, keys, wallet
transaction    → shared_kernel, address
bitcoin_node   → shared_kernel, rpc_client, wallet, address, transaction
ui_kit         → (none)
```

If a cycle appears (e.g., wallet ↔ address):
- Extract shared contract into shared_kernel
- Or create a lightweight value object (like DerivedAddress) in the lower-level module
- Or replace direct dependency with id reference

---

## DI / Bootstrap Graph

```
main()
  → AppDependenciesBuilder.build()
    → BitcoinRpcClient               (rpc_client)
    → SecureStorageImpl               (storage)

    → KeysAssembly                    (keys module)
      → Bip39ServiceImpl
      → KeyDerivationServiceImpl
      → SeedRepositoryImpl

    → WalletRemoteDataSourceImpl      (bitcoin_node)
    → WalletAssembly                  (wallet module)
      → WalletRepositoryImpl
      → CreateNodeWalletUseCase
      → CreateHdWalletUseCase
      → RestoreHdWalletUseCase

    → AddressRemoteDataSourceImpl     (bitcoin_node)
    → AddressAssembly                 (address module)
      → AddressRepositoryImpl
      → GenerateAddressUseCase (+ strategies)

    → TransactionAssembly             (transaction module)
      → HdAddressDataSourceImpl       (lib/core/adapters/ — bridges address + transaction)
      → PrepareHdSendUseCase          (application/hd/)
      → SendHdTransactionUseCase      (application/hd/)
      → PrepareNodeSendUseCase        (application/node/)
      → SendNodeTransactionUseCase    (application/node/)
      → BroadcastTransactionUseCase
      → GetTransactionsUseCase
      → GetTransactionDetailUseCase
      → GetUtxosUseCase
      → ScanUtxosUseCase

    → AppDependencies                 (container: keys, wallet, address, transaction assemblies)
    → App widget
```

Each Assembly creates: data/ implementations, application/ services, public module API.

Feature Scopes provide BLoC **factory** via static methods + InheritedWidget.

---

## Key Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| DataSource interfaces owned by consumers, not adapter | DIP: high-level defines contract, low-level implements. ISP: each module gets exactly the interface it needs |
| ISP split of remote data sources | Single Responsibility: each interface has one reason to change |
| Mnemonic in keys, not wallet | Information Expert: crypto/key-management context owns crypto primitives |
| DerivedAddress in keys | Avoids keys→address cycle; keys returns lightweight VO, address builds full entity |
| AddressType in shared_kernel | Used by both keys and address — shared primitive, not owned by either |
| SecureStorage interface in shared_kernel | Allows pure Dart packages (keys, wallet, address) to depend on the interface without pulling Flutter |
| SecureStorageImpl in storage (Flutter) | Only the app layer and composition root need the Flutter implementation |
| Strategies in application, not domain | Strategies do IO (call services, repositories) — domain must stay pure |
| Per-flow BLoC, not per-feature | SRP: one BLoC handles one flow. Prevents god-object accumulation |
| Serializer pattern (single final class) | Replaces abstract Codec/Mapper + Impl hierarchy — simpler, no separate files |
| Assembly per module | Each module owns its DI, not a monolithic builder |
| hd/ and node/ subfolders in application/ | Trust boundary enforcement: HD and Node use cases cannot cross-import within the same package |
| transaction package owns UTXO domain | Single Responsibility: UTXO lifecycle is a transaction concern, not wallet or address |
| No Event Sourcing / CQRS | Mobile client over Bitcoin Core's ledger — Core already does ES for us |

---

## What Goes in shared_kernel

Only very small shared primitives and contracts:

- BitcoinNetwork
- AddressType
- SecureStorage (interface)
- Failure / Result (future)
- Amount / Money (future)

**Never** put in shared_kernel: large entities, module repositories, use cases, "everything shared just in case."
