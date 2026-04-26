# shared_kernel

## Purpose

Leaf package that holds the smallest possible set of primitives shared by every
other workspace package. It carries zero business logic and has no workspace
dependencies of its own.

## Public API

Barrel: `package:shared_kernel/shared_kernel.dart`

| Symbol | Kind | Description |
|---|---|---|
| `AddressType` | enum | P2PKH / P2WPKH / P2TR address type discriminant |
| `BitcoinNetwork` | enum | `mainnet` / `testnet` / `regtest` network tag |
| `Satoshi` | typedef | `int` alias used for all satoshi amounts |
| `SecureStorage` | abstract class | Key-value storage contract used by `storage` and `keys` |

## Dependencies

Workspace packages: none (leaf).
Third-party: none.
SDK: Dart SDK only.

## When to add here

Add a symbol only when all of the following are true:

- It is needed by at least two other packages.
- It carries zero business logic (no entities, no repositories, no use cases, no
  module-specific types).
- It is a primitive type alias, enum, or abstract contract.

Never add entities, repositories, use cases, or types that belong to a single
domain module.

## Layer layout

```
lib/
  shared_kernel.dart          # barrel
  src/
    address_type.dart
    bitcoin_network.dart
    satoshi.dart
    secure_storage.dart
```
