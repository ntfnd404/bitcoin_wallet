# bitcoin_node

## Purpose

Bitcoin Core RPC adapter. Implements every remote data-source interface defined
in the domain packages (`address`, `transaction`, `wallet`) by calling the
Bitcoin Core JSON-RPC API through `rpc_client`. This package contains only data
layer code; it has no domain entities or use cases of its own.

Wired exclusively in `lib/core/di/app_dependencies_builder.dart` in the app
shell. No other package depends on `bitcoin_node`.

## Public API

Barrel: `package:bitcoin_node/bitcoin_node.dart`

| Symbol | Kind | Implements |
|---|---|---|
| `AddressRemoteDataSourceImpl` | final class | `AddressRemoteDataSource` |
| `BlockGenerationDataSourceImpl` | final class | `BlockGenerationDataSource` |
| `BroadcastDataSourceImpl` | final class | `BroadcastDataSource` |
| `NodeTransactionDataSourceImpl` | final class | `NodeTransactionDataSource` |
| `TransactionRemoteDataSourceImpl` | final class | `TransactionRemoteDataSource` |
| `UtxoRemoteDataSourceImpl` | final class | `UtxoRemoteDataSource` |
| `UtxoScanDataSourceImpl` | final class | `UtxoScanDataSource` |
| `WalletRemoteDataSourceImpl` | final class | `WalletRemoteDataSource` |

## Dependencies

Workspace packages: `address`, `rpc_client`, `shared_kernel`, `transaction`,
`wallet`.
Third-party: none.
SDK: Dart SDK only.

## When to add here

Add a symbol only when it is a concrete implementation of a remote data-source
interface and the implementation calls Bitcoin Core over JSON-RPC. Never add
domain entities, use cases, local storage adapters, or any symbol that is not
an RPC data-source implementation.

## Layer layout

```
lib/
  bitcoin_node.dart           # barrel (no assembly — wired in app_dependencies_builder.dart)
  src/
    address/
      address_remote_data_source_impl.dart
    block/
      block_generation_data_source_impl.dart
    transaction/
      broadcast_data_source_impl.dart
      node_transaction_data_source_impl.dart
      transaction_remote_data_source_impl.dart
    utxo/
      utxo_remote_data_source_impl.dart
      utxo_scan_data_source_impl.dart
    wallet/
      wallet_remote_data_source_impl.dart
```
