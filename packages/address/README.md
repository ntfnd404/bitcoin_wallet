# address

## Purpose

Address domain module. Owns the `Address` entity and the use case that
generates addresses. Uses the Strategy pattern to support two address sources:
HD derivation (via `keys`) and Bitcoin Core node allocation. Consumers request
an address without needing to know which strategy is active.

Assembly entry point: `package:address/address_assembly.dart` — `AddressAssembly`.

## Public API

Barrel: `package:address/address.dart`

### Application

| Symbol | Kind | Description |
|---|---|---|
| `AddressGenerationStrategy` | abstract class | Strategy contract for address generation |
| `GenerateAddressUseCase` | class | Selects the appropriate strategy and generates an address |
| `HdAddressGenerationStrategy` | class | Derives an address from the HD key tree |
| `NodeAddressGenerationStrategy` | class | Requests a new address from Bitcoin Core |

### Domain data sources

| Symbol | Kind | Description |
|---|---|---|
| `AddressLocalDataSource` | abstract class | Reads and writes address records to local secure storage |
| `AddressRemoteDataSource` | abstract class | Requests addresses from a Bitcoin Core node |

### Domain entity

| Symbol | Kind | Description |
|---|---|---|
| `Address` | class | A Bitcoin address with metadata |

### Domain repository

| Symbol | Kind | Description |
|---|---|---|
| `AddressRepository` | abstract class | Persistence contract for address records |

### Assembly

| Symbol | Kind | Description |
|---|---|---|
| `AddressAssembly` | final class | Wires all implementations; exposes `addressRepository` and `generateAddress` |

## Dependencies

Workspace packages: `keys`, `shared_kernel`, `wallet`.
Third-party: none.
SDK: Dart SDK only.

## When to add here

Add a symbol only when it is an address entity, an address repository contract,
or a use case / strategy that generates or persists addresses. Never add
transaction, UTXO, or wallet creation logic here.

## Layer layout

```
lib/
  address.dart                # barrel
  address_assembly.dart       # DI factory
  src/
    application/
      address_generation_strategy.dart
      generate_address_use_case.dart
      hd/
        hd_address_generation_strategy.dart
      node/
        node_address_generation_strategy.dart
    data/
      address_local_data_source_impl.dart
      address_mapper.dart
      address_repository_impl.dart
    domain/
      data_sources/
        address_local_data_source.dart
        address_remote_data_source.dart
      entity/
        address.dart
      repository/
        address_repository.dart
```
