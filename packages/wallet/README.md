# wallet

## Purpose

Wallet domain module. Owns the `Wallet` entity hierarchy (`NodeWallet`,
`HdWallet`) and the use cases that create or restore wallets. Delegates seed
and key operations to the `keys` package. Does not generate addresses; that
is the responsibility of the `address` package.

Assembly entry point: `package:wallet/wallet_assembly.dart` — `WalletAssembly`.

## Public API

Barrel: `package:wallet/wallet.dart`

### Use cases

| Symbol | Kind | Description |
|---|---|---|
| `CreateHdWalletUseCase` | class | Generates a mnemonic and persists an HD wallet |
| `CreateNodeWalletUseCase` | class | Creates a custodial node wallet record |
| `RestoreHdWalletUseCase` | class | Restores an HD wallet from an existing mnemonic |

### Domain data sources

| Symbol | Kind | Description |
|---|---|---|
| `WalletLocalDataSource` | abstract class | Reads and writes wallet records to local secure storage |
| `WalletRemoteDataSource` | abstract class | Reads and writes wallet records on a Bitcoin Core node |

### Domain entities

| Symbol | Kind | Description |
|---|---|---|
| `Wallet` | sealed class | Base type for all wallet variants |
| `HdWallet` | class | Non-custodial HD wallet (part of `Wallet`) |
| `NodeWallet` | class | Custodial node wallet (part of `Wallet`) |

### Domain repositories

| Symbol | Kind | Description |
|---|---|---|
| `HdWalletRepository` | abstract class | Persistence contract for HD wallets |
| `NodeWalletRepository` | abstract class | Persistence contract for node wallets |
| `WalletRepository` | abstract class | Combined persistence contract for all wallet variants |

### Assembly

| Symbol | Kind | Description |
|---|---|---|
| `WalletAssembly` | final class | Wires all implementations; exposes use cases and the repository |

## Dependencies

Workspace packages: `keys`, `shared_kernel`.
Third-party: `uuid: 4.5.3`.
SDK: Dart SDK only.

## When to add here

Add a symbol only when it is a wallet entity, a wallet repository contract, or
a use case that creates, restores, or persists a wallet record. Never add
address generation, transaction logic, or RPC concerns here.

## Layer layout

```
lib/
  wallet.dart                 # barrel
  wallet_assembly.dart        # DI factory
  src/
    application/
      hd/
        create_hd_wallet_use_case.dart
        restore_hd_wallet_use_case.dart
      node/
        create_node_wallet_use_case.dart
    data/
      wallet_local_data_source_impl.dart
      wallet_mapper.dart
      wallet_repository_impl.dart
    domain/
      data_sources/
        wallet_local_data_source.dart
        wallet_remote_data_source.dart
      entity/
        wallet.dart
        hd_wallet.dart        # part of wallet.dart
        node_wallet.dart      # part of wallet.dart
      repository/
        hd_wallet_repository.dart
        node_wallet_repository.dart
        wallet_repository.dart
```
