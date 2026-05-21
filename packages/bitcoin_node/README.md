# bitcoin_node

## Package type: Infrastructure (adapter)

Bitcoin Core RPC adapter. Implements every gateway interface defined in the
domain packages (`transaction`, `wallet`) by calling Bitcoin Core JSON-RPC
through `rpc_client`. Contains only adapter code — no domain entities, no use
cases, no business logic.

Wired exclusively in `lib/core/di/app_dependencies_builder.dart`. No other
package depends on `bitcoin_node`.

## Internal structure

**Domain-concept folders** — not Clean Architecture layers.

All files in this package are gateway adapters (data layer). Splitting them
further into a `data/gateway/` layer would add a folder level with no benefit.
Instead files are grouped by the Bitcoin Core domain they cover:

```
lib/src/
  address/
    address_type_rpc.dart           ← RPC address-type string constants
    node_address_gateway_impl.dart  ← implements NodeAddressGateway (wallet)
  block/
    block_generation_gateway_impl.dart  ← implements BlockGenerationGateway (transaction)
  transaction/
    broadcast_gateway_impl.dart         ← implements BroadcastGateway (transaction)
    node_transaction_gateway_impl.dart  ← implements NodeTransactionGateway (transaction)
    transaction_direction_rpc_mapper.dart
    transaction_history_gateway_impl.dart ← implements TransactionHistoryGateway (transaction)
  utxo/
    address_type_rpc_mapper.dart
    utxo_gateway_impl.dart          ← implements UtxoGateway (transaction)
    utxo_scan_gateway_impl.dart     ← implements UtxoScanGateway (transaction)
  wallet/
    node_wallet_gateway_impl.dart   ← implements NodeWalletGateway (wallet)
```

### Why domain-concept folders instead of layers

This package has no domain or application layer — every file is an adapter.
A `data/gateway/` split would add one folder level with no structural benefit.
Grouping by domain concept (`address/`, `transaction/`, `utxo/`) makes it
immediately clear which Bitcoin Core subsystem a file touches.

## Public API

Barrel: `package:bitcoin_node/bitcoin_node.dart`

| Symbol | Implements |
|---|---|
| `NodeAddressGatewayImpl` | `NodeAddressGateway` (wallet) |
| `BlockGenerationGatewayImpl` | `BlockGenerationGateway` (transaction) |
| `BroadcastGatewayImpl` | `BroadcastGateway` (transaction) |
| `NodeTransactionGatewayImpl` | `NodeTransactionGateway` (transaction) |
| `TransactionHistoryGatewayImpl` | `TransactionHistoryGateway` (transaction) |
| `UtxoGatewayImpl` | `UtxoGateway` (transaction) |
| `UtxoScanGatewayImpl` | `UtxoScanGateway` (transaction) |
| `NodeWalletGatewayImpl` | `NodeWalletGateway` (wallet) |

## Dependencies

Workspace packages: `rpc_client`, `shared_kernel`, `transaction`, `wallet`.
Third-party: none.
SDK: Dart SDK only.

## When to add here

Only concrete RPC gateway implementations. Never add domain entities, use
cases, local storage adapters, or any non-RPC symbol.
