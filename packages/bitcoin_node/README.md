# bitcoin_node

## Purpose

Bitcoin Core RPC adapter. Implements every gateway interface defined
in the domain packages (`transaction`, `wallet`) by calling the
Bitcoin Core JSON-RPC API through `rpc_client`. This package contains only data
layer code; it has no domain entities or use cases of its own.

Wired exclusively in `lib/core/di/app_dependencies_builder.dart` in the app
shell. No other package depends on `bitcoin_node`.

## Public API

Barrel: `package:bitcoin_node/bitcoin_node.dart`

| Symbol | Kind | Implements |
|---|---|---|
| `NodeAddressGatewayImpl` | final class | `NodeAddressGateway` (`wallet`) |
| `BlockGenerationGatewayImpl` | final class | `BlockGenerationGateway` (`transaction`) |
| `BroadcastGatewayImpl` | final class | `BroadcastGateway` (`transaction`) |
| `NodeTransactionGatewayImpl` | final class | `NodeTransactionGateway` (`transaction`) |
| `TransactionHistoryGatewayImpl` | final class | `TransactionHistoryGateway` (`transaction`) |
| `UtxoGatewayImpl` | final class | `UtxoGateway` (`transaction`) |
| `UtxoScanGatewayImpl` | final class | `UtxoScanGateway` (`transaction`) |
| `NodeWalletGatewayImpl` | final class | `NodeWalletGateway` (`wallet`) |

## Dependencies

Workspace packages: `rpc_client`, `shared_kernel`, `transaction`, `wallet`.
Third-party: none.
SDK: Dart SDK only.

## When to add here

Add a symbol only when it is a concrete implementation of a gateway interface
and the implementation calls Bitcoin Core over JSON-RPC. Never add domain
entities, use cases, local storage adapters, or any symbol that is not
an RPC gateway implementation.

## Layer layout

```
lib/
  bitcoin_node.dart           # barrel (no assembly — wired in app_dependencies_builder.dart)
  src/
    address/
      node_address_gateway_impl.dart
    block/
      block_generation_gateway_impl.dart
    transaction/
      broadcast_gateway_impl.dart
      node_transaction_gateway_impl.dart
      transaction_history_gateway_impl.dart
    utxo/
      utxo_gateway_impl.dart
      utxo_scan_gateway_impl.dart
    wallet/
      node_wallet_gateway_impl.dart
```
