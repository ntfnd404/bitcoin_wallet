# Phase 3: Data — RPC & Node Wallet

Status: `PLAN_APPROVED`
Ticket: BW-0001

---

## Goal

Implement the data layer for Node Wallet: `SecureStorage` adapter, `NodeWalletRepositoryImpl`
(Bitcoin Core RPC), and address verification.

---

## Context

Phase 2 delivered all domain interfaces. Phase 3 wires the first real implementations:
- `SecureStorage` wraps `flutter_secure_storage` (already scaffolded, needs hardening)
- `NodeWalletRepositoryImpl` calls Bitcoin Core RPC (`createwallet`, `getnewaddress`)
- Wallet metadata (id, createdAt) stored in `SecureStorage` as JSON (no SQLite needed)
- HD methods throw `UnsupportedError` — Phase 4 scope

After Phase 3, `AppDependenciesBuilder` wires `NodeWalletRepositoryImpl` into `AppDependencies`.
HD repo and seed repo stubs remain until Phase 4.

---

## Tasks

- [x] **3.1** `SecureStorage` — harden to `final class`, fix `any` versions in pubspec
- [x] **3.2** `NodeWalletRepositoryImpl` — `createNodeWallet` + `generateAddress` + `getWallets` + `getAddresses`
- [x] **3.3** Address verification — integration test against live regtest node

---

## Acceptance Criteria

- `packages/storage` has exact version for `flutter_secure_storage` (no `any`)
- `packages/data` has exact versions for all deps (no `any`)
- `NodeWalletRepositoryImpl` creates wallets and generates addresses via RPC
- Legacy address starts `m`, bech32 starts `bcrt1q`, bech32m starts `bcrt1p`
- HD methods (`createHDWallet`, `restoreHDWallet`) throw `UnsupportedError`
- Integration test: `createNodeWallet` + `generateAddress` all 4 types → correct prefixes
- `flutter analyze` — zero warnings
- App launches on macOS

---

## Technical Details

### RPC address type mapping

| `AddressType` | RPC `address_type` param |
|---------------|--------------------------|
| `legacy` | `"legacy"` |
| `wrappedSegwit` | `"p2sh-segwit"` |
| `nativeSegwit` | `"bech32"` |
| `taproot` | `"bech32m"` |

### Wallet metadata storage

Key pattern: `node_wallet_<id>` → JSON `{id, name, createdAt}`
Key pattern: `node_wallets_index` → JSON array of wallet ids
Key pattern: `node_addresses_<walletId>` → JSON array of address objects

### NodeWalletRepositoryImpl skeleton

```dart
final class NodeWalletRepositoryImpl implements WalletRepository {
  const NodeWalletRepositoryImpl({
    required BitcoinRpcClient rpcClient,
    required SecureStorage storage,
  });
  // createNodeWallet → RPC createwallet → store metadata → return Wallet
  // generateAddress → RPC getnewaddress with type → store → return Address
  // getWallets → read index → load each wallet metadata
  // getAddresses → read stored address list
  // createHDWallet / restoreHDWallet → throw UnsupportedError
}
```

### SecureStorage fix

- Add `final` modifier
- Fix `static const _storage` → instance field (for testability)
- Exact dep version in pubspec
