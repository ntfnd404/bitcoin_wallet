# transaction

## Purpose

Transaction and UTXO domain module. Owns entities, repositories, use cases, and
coin-selection services for building, broadcasting, and querying transactions on
both the HD and node wallet paths.

The `address` dependency was added in Phase 2. `HdAddressEntry`, which
previously carried address data inline, was removed in Phase 2; use cases now
work with `Address` (from the `address` package) directly.

Assembly entry point: `package:transaction/transaction_assembly.dart` —
`TransactionAssembly`.

## Public API

Barrel: `package:transaction/transaction.dart`

### Use cases

| Symbol | Kind | Description |
|---|---|---|
| `BroadcastTransactionUseCase` | class | Broadcasts a signed transaction to the network |
| `GetTransactionDetailUseCase` | class | Fetches full details for a single transaction |
| `GetTransactionsUseCase` | class | Lists transactions for a wallet |
| `GetUtxosUseCase` | class | Returns the UTXO set for a wallet |
| `ScanUtxosUseCase` | class | Scans the chain for UTXOs belonging to HD addresses |
| `PrepareHdSendUseCase` | class | Builds an unsigned HD send (coin selection + fee estimation) |
| `PrepareNodeSendUseCase` | class | Builds an unsigned node send |
| `SendHdTransactionUseCase` | class | Signs and broadcasts an HD transaction |
| `SendNodeTransactionUseCase` | class | Sends a transaction via the node RPC |

### HD send preparation types

| Symbol | Kind | Description |
|---|---|---|
| `HdSendPreparation` | class | Result of `PrepareHdSendUseCase` |
| `NodeSendPreparation` | class | Result of `PrepareNodeSendUseCase` |

### Domain data sources

| Symbol | Kind | Description |
|---|---|---|
| `BlockGenerationDataSource` | abstract class | Mines blocks in regtest (testing utility) |
| `BroadcastDataSource` | abstract class | Broadcasts raw transactions |
| `HdAddressDataSource` | abstract class | Provides HD addresses for change and scan operations |
| `NodeTransactionDataSource` | abstract class | Node-specific transaction operations |
| `TransactionRemoteDataSource` | abstract class | Reads transactions from a node |
| `UtxoRemoteDataSource` | abstract class | Reads UTXOs from a node |
| `UtxoScanDataSource` | abstract class | Scans UTXOs across the chain |

### Domain entities

| Symbol | Kind | Description |
|---|---|---|
| `BroadcastedTx` | class | Result of a successful broadcast |
| `ScannedUtxo` | class | UTXO found during an HD address scan |
| `Transaction` | class | Transaction summary record |
| `TransactionDetail` | class | Full transaction data including inputs and outputs |
| `TransactionDirection` | enum | `incoming` / `outgoing` discriminant |
| `TransactionInput` | class | A single transaction input |
| `TransactionOutput` | class | A single transaction output |
| `Utxo` | class | Unspent transaction output |

### Domain exceptions

| Symbol | Kind | Description |
|---|---|---|
| `InsufficientFundsException` | class | Thrown when available UTXOs cannot cover the send amount plus fee |

### Domain repositories

| Symbol | Kind | Description |
|---|---|---|
| `TransactionRepository` | abstract class | Persistence and query contract for transactions |
| `UtxoRepository` | abstract class | Persistence and query contract for UTXOs |

### Domain services

| Symbol | Kind | Description |
|---|---|---|
| `CoinSelector` | abstract class | Strategy contract for coin selection |
| `CoinSelectorBase` | abstract class | Base implementation shared by concrete selectors |
| `FeeEstimator` | abstract class | Fee estimation contract |
| `FifoCoinSelector` | class | First-in-first-out coin selector |
| `LifoCoinSelector` | class | Last-in-first-out coin selector |
| `MinimizeChangeCoinSelector` | class | Minimises change output coin selector |
| `MinimizeInputsCoinSelector` | class | Minimises the number of inputs coin selector |
| `TransactionSigner` | abstract class | Signs a prepared transaction |

### Domain value objects

| Symbol | Kind | Description |
|---|---|---|
| `CoinCandidate` | class | A UTXO considered for inclusion in a send |
| `CoinSelectionResult` | class | Output of a coin selection algorithm |
| `SigningInput` | class | Input descriptor for transaction signing (transaction-level) |

### Assembly

| Symbol | Kind | Description |
|---|---|---|
| `TransactionAssembly` | final class | Wires all implementations; exposes use cases and `blockGeneration` |

## Dependencies

Workspace packages: `address` (added Phase 2), `shared_kernel`.
Third-party: none.
SDK: Dart SDK only.

Note: `HdAddressEntry` was removed in Phase 2. Use cases that previously
consumed `HdAddressEntry` now receive `Address` from the `address` package
directly.

## When to add here

Add a symbol only when it is a transaction entity, a UTXO entity, a
repository or data-source contract for transactions/UTXOs, a use case that
builds or queries transactions, or a coin-selection / fee-estimation service.
Never add wallet or address entities here.

## Layer layout

```
lib/
  transaction.dart            # barrel
  transaction_assembly.dart   # DI factory
  src/
    application/
      broadcast_transaction_use_case.dart
      get_transaction_detail_use_case.dart
      get_transactions_use_case.dart
      get_utxos_use_case.dart
      scan_utxos_use_case.dart
      hd/
        hd_send_preparation.dart
        prepare_hd_send_use_case.dart
        send_hd_transaction_use_case.dart
      node/
        node_send_preparation.dart
        prepare_node_send_use_case.dart
        send_node_transaction_use_case.dart
    data/
      transaction_repository_impl.dart
      utxo_repository_impl.dart
    domain/
      data_sources/
        block_generation_data_source.dart
        broadcast_data_source.dart
        hd_address_data_source.dart
        node_transaction_data_source.dart
        transaction_remote_data_source.dart
        utxo_remote_data_source.dart
        utxo_scan_data_source.dart
      entity/
        broadcasted_tx.dart
        scanned_utxo.dart
        transaction.dart
        transaction_detail.dart
        transaction_direction.dart
        transaction_input.dart
        transaction_output.dart
        utxo.dart
      exception/
        insufficient_funds_exception.dart
      repository/
        transaction_repository.dart
        utxo_repository.dart
      service/
        coin_selector.dart
        coin_selector_base.dart
        fee_estimator.dart
        fifo_coin_selector.dart
        lifo_coin_selector.dart
        minimize_change_coin_selector.dart
        minimize_inputs_coin_selector.dart
        transaction_signer.dart
      value_object/
        coin_candidate.dart
        coin_selection_result.dart
        signing_input.dart
```
