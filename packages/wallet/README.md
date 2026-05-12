# wallet

## Purpose

Wallet domain module. Owns the `Wallet` entity hierarchy (`NodeWallet`,
`HdWallet`), the `Address` value object, and the use cases that create,
restore, or persist wallets and generate addresses for them. Delegates seed
and key operations to the `keys` package.

Since BW-0011 the wallet package absorbs the former `address` package:
addresses do not have an independent aggregate root; they are always operated
on as part of the wallet aggregate.

Assembly entry point: `package:wallet/wallet_assembly.dart` — `WalletAssembly`.

## Public API

Barrel: `package:wallet/wallet.dart`

### Use cases

| Symbol | Kind | Description |
|---|---|---|
| `CreateHdWalletUseCase` | class | Generates a mnemonic and persists an HD wallet |
| `CreateNodeWalletUseCase` | class | Creates a custodial node wallet record |
| `RestoreHdWalletUseCase` | class | Restores an HD wallet from an existing mnemonic |
| `GenerateAddressUseCase` | class | Generates the next address for a wallet via strategy dispatch |

### Application strategies

| Symbol | Kind | Description |
|---|---|---|
| `AddressGenerationStrategy` | abstract class | Strategy port: dispatches address generation by wallet trust model |
| `HdAddressGenerationStrategy` | class | Derives addresses locally via BIP32 for HD wallets |
| `NodeAddressGenerationStrategy` | class | Requests addresses from Bitcoin Core for node wallets |

### Domain entities

| Symbol | Kind | Description |
|---|---|---|
| `Wallet` | sealed class | Base type for all wallet variants |
| `HdWallet` | class | Non-custodial HD wallet (part of `Wallet`) |
| `NodeWallet` | class | Custodial node wallet (part of `Wallet`) |
| `Address` | value object | Bitcoin address with type, walletId, index, and (HD-only) derivationPath |

### Domain exceptions

| Symbol | Kind | Description |
|---|---|---|
| `WalletException` | sealed class | Base type for wallet bounded-context exceptions |
| `WalletNotFoundException` | class | No wallet for the given identifier |
| `WalletAlreadyExistsException` | class | A wallet with the same name already exists |
| `WalletInvalidMnemonicException` | class | BIP39 mnemonic failed checksum validation |
| `WalletStorageException` | class | Wallet persistence failure |
| `WalletNodeException` | class | Bitcoin Core RPC or network error |
| `AddressException` | sealed class | Base type for address bounded-context exceptions |
| `AddressNoStrategyException` | class | No registered strategy supports the given wallet |
| `AddressGenerationException` | class | A strategy failed to generate an address |
| `AddressStorageException` | class | Address persistence failure |

### Domain repositories

| Symbol | Kind | Description |
|---|---|---|
| `HdWalletRepository` | abstract class | Persistence contract for HD wallets |
| `NodeWalletRepository` | abstract class | Persistence contract for node wallets |
| `WalletRepository` | abstract class | Combined persistence contract for all wallet variants |
| `AddressRepository` | abstract class | Persistence contract for addresses (per-wallet index, list, save) |

### Domain gateways (outbound ports)

| Symbol | Kind | Description |
|---|---|---|
| `NodeWalletGateway` | abstract class | Outbound port to Bitcoin Core for wallet RPC operations |
| `NodeAddressGateway` | abstract class | Outbound port to Bitcoin Core for address RPC operations |

### Assembly

| Symbol | Kind | Description |
|---|---|---|
| `WalletAssembly` | final class | Wires wallet + address implementations; exposes use cases and repositories |

## Dependencies

Workspace packages: `keys`, `shared_kernel`, `storage`.
Third-party: `uuid: 4.5.3`.
SDK: Dart SDK only.

## When to add here

Add a symbol only when it concerns a wallet entity, an address as part of a
wallet, a wallet/address repository contract, or a use case that creates,
restores, persists, or generates addresses for a wallet record. Do not add
transaction logic, UTXO selection, or RPC concerns here — those belong in
`transaction` or `bitcoin_node`.

## Layer layout

```
lib/
  wallet.dart                              # barrel
  wallet_assembly.dart                     # DI factory
  src/
    application/
      address_generation_strategy.dart     # strategy port
      generate_address_use_case.dart       # strategy dispatcher
      hd/
        create_hd_wallet_use_case.dart
        hd_address_generation_strategy.dart
        restore_hd_wallet_use_case.dart
      node/
        create_node_wallet_use_case.dart
        node_address_generation_strategy.dart
    data/
      address_mapper.dart
      address_repository_impl.dart
      wallet_local_data_source.dart        # internal storage port (not exported)
      wallet_local_data_source_impl.dart
      wallet_mapper.dart
      wallet_repository_impl.dart
    domain/
      entity/
        address.dart
        hd_wallet.dart                     # part of wallet.dart
        node_wallet.dart                   # part of wallet.dart
        wallet.dart
      exception/
        address_exception.dart
        wallet_exception.dart
      gateway/
        node_address_gateway.dart
        node_wallet_gateway.dart
      repository/
        address_repository.dart
        hd_wallet_repository.dart
        node_wallet_repository.dart
        wallet_repository.dart
```
