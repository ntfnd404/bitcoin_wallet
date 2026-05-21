# wallet

## Package type: Business

Owns wallet entities (NodeWallet, HdWallet), address management, and wallet
creation/restoration use cases. Acts as the source of truth for wallet identity
across the app.

## Internal structure

**Clean Architecture layers** — `domain/`, `application/`, `data/`.

```
lib/src/
  domain/
    data_source/          ← WalletLocalDataSource interface (platform storage contract)
    entity/               ← Wallet (sealed), NodeWallet, HdWallet, Address
    exception/            ← WalletException, AddressException
    gateway/              ← NodeWalletGateway, NodeAddressGateway (outbound RPC ports)
    repository/           ← WalletRepository, AddressRepository, HdWalletRepository, …
  application/
    hd/                   ← CreateHdWalletUseCase, RestoreHdWalletUseCase,
    │                        HdAddressGenerationStrategy
    node/                 ← CreateNodeWalletUseCase, NodeAddressGenerationStrategy
    generate_address_use_case.dart
    address_generation_strategy.dart
  data/
    data_source/          ← WalletLocalDataSourceImpl (implements domain/data_source/)
    repository/           ← AddressRepositoryImpl, WalletRepositoryImpl
    │                        + AddressMapper, WalletMapper (private to their impl)
```

### Why `data/` is split this way

`data/` subfolders mirror `domain/` subfolders:

| `domain/` | `data/` | What it holds |
|---|---|---|
| `domain/repository/` | `data/repository/` | `*RepositoryImpl` + their private mappers |
| `domain/data_source/` | `data/data_source/` | `WalletLocalDataSourceImpl` |

Mappers live alongside the impl that uses them — no separate `mapper/` folder.

## Public API

Barrel: `package:wallet/wallet.dart`
Assembly: `package:wallet/wallet_assembly.dart` — `WalletAssembly`

| Symbol | Kind | Description |
|---|---|---|
| `Wallet` | sealed class | Base wallet type |
| `NodeWallet` | class | Custodial wallet backed by Bitcoin Core |
| `HdWallet` | class | Non-custodial wallet with BIP-39 seed |
| `Address` | class | Derived or RPC-provided Bitcoin address |
| `WalletRepository` | abstract class | CRUD contract for wallets |
| `AddressRepository` | abstract class | Address storage and derivation contract |
| `NodeWalletGateway` | abstract class | RPC port for node wallet operations |
| `NodeAddressGateway` | abstract class | RPC port for address generation |
| `CreateHdWalletUseCase` | class | Creates HD wallet from generated mnemonic |
| `RestoreHdWalletUseCase` | class | Restores HD wallet from existing mnemonic |
| `CreateNodeWalletUseCase` | class | Creates a node-managed wallet via RPC |
| `GenerateAddressUseCase` | class | Generates or derives next address |
| `WalletAssembly` | final class | DI factory |

## Dependencies

Workspace packages: `shared_kernel`, `keys`, `storage`.
Third-party: none.
