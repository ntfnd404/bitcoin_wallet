# shared_kernel

## Package type: Shared kernel

The smallest possible set of primitives shared by every other workspace package.
Zero business logic, zero workspace dependencies.

## Internal structure

**Flat.** All symbols are at the same abstraction level — no subfolders needed.

```
lib/src/
  address_type.dart     ← AddressType enum
  bitcoin_network.dart  ← BitcoinNetwork enum
  satoshi.dart          ← Satoshi value object
  secure_storage.dart   ← SecureStorage abstract interface
```

### Why flat

Every file is an independent primitive with no internal hierarchy. Subfolders
would only add navigation depth without conveying structure.

## Public API

Barrel: `package:shared_kernel/shared_kernel.dart`

| Symbol | Kind | Description |
|---|---|---|
| `AddressType` | enum | `legacy` / `wrappedSegwit` / `nativeSegwit` / `taproot` |
| `BitcoinNetwork` | enum | `mainnet` / `testnet` / `regtest` |
| `Satoshi` | final class | Satoshi value object with `btcAmount`, `btcDisplay`, `fromBtc` |
| `SecureStorage` | abstract class | Key-value storage contract |

## Rule for adding here

A symbol belongs here only when: (1) needed by ≥ 2 packages, (2) carries zero
business logic, (3) is a primitive type, enum, or abstract contract.

## Dependencies

Workspace packages: none (leaf).
Third-party: none.
SDK: Dart SDK only.
