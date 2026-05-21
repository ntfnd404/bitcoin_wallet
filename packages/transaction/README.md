# transaction

## Purpose

Transaction and UTXO domain module. Owns entities, repositories, use cases, and
coin-selection services for building, broadcasting, and querying transactions on
both the HD and node wallet paths.

Assembly entry point: `package:transaction/transaction_assembly.dart` —
`TransactionAssembly`.

## Public API

Barrel: `package:transaction/transaction.dart`

### Use cases

| Symbol | Kind | Description |
|---|---|---|
| `PrepareHdSendUseCase` | class | Builds an unsigned HD send (coin selection + fee estimation) |
| `PrepareNodeSendUseCase` | class | Builds an unsigned node send |
| `SendHdTransactionUseCase` | class | Signs and broadcasts an HD transaction |
| `SendNodeTransactionUseCase` | class | Sends a transaction via the node RPC |
| `SendOpReturnUseCase` | class | Constructs, signs, and broadcasts an OP_RETURN transaction |

### Send workflow types

| Symbol | Kind | Description |
|---|---|---|
| `SendWorkflow` | abstract class | Two-step send contract (prepare → confirm) |
| `SendPreparation` | sealed class | Opaque result of the prepare phase |
| `HdSendPreparation` | class | HD-specific preparation detail |
| `NodeSendPreparation` | class | Node-specific preparation detail |

### Domain gateways

| Symbol | Kind | Description |
|---|---|---|
| `BlockGenerationGateway` | abstract class | Mines blocks in regtest (testing utility) |
| `BroadcastGateway` | abstract class | Broadcasts raw transactions |
| `NodeTransactionGateway` | abstract class | Node-specific transaction operations |
| `TransactionHistoryGateway` | abstract class | Reads transaction history from a node |
| `UtxoGateway` | abstract class | Reads UTXOs from a node |
| `UtxoScanGateway` | abstract class | Scans UTXOs across the chain |

### Domain repositories

| Symbol | Kind | Description |
|---|---|---|
| `TransactionRepository` | abstract class | Query contract for transactions |
| `UtxoRepository` | abstract class | Query contract for UTXOs |

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
| `TransactionException` | sealed class | Base for all transaction domain exceptions |
| `InsufficientFundsException` | class | Thrown when UTXOs cannot cover amount + fee |

### Domain services

| Symbol | Kind | Description |
|---|---|---|
| `CoinSelector` | abstract class | Strategy contract for coin selection |
| `CoinSelectorBase` | abstract class | Base implementation shared by concrete selectors |
| `CoinSelectionRecommender` | abstract class | Picks the best strategy by waste score |
| `DefaultCoinSelectionRecommender` | class | Default waste-score recommender |
| `FeeEstimator` | abstract class | Fee estimation contract |
| `P2wpkhFeeEstimator` | class | P2WPKH-aware fee estimator |
| `UtxoEligibilityFilter` | abstract class | Filters UTXOs before coin selection |
| `DefaultUtxoEligibilityFilter` | class | Default eligibility filter |
| `ScriptClassifier` | abstract class | Classifies scriptPubKey hex to ScriptType |
| `DefaultScriptClassifier` | class | Byte-pattern classifier |
| `ScriptDecoder` | abstract class | Decodes script hex to asm notation |
| `DefaultScriptDecoder` | class | Asm decoder for all standard script types |
| `buildOpReturnScript` | function | Builds OP_RETURN scriptPubKey hex for raw bytes |
| `FifoCoinSelector` | class | First-in-first-out coin selector |
| `LifoCoinSelector` | class | Last-in-first-out coin selector |
| `MinimizeChangeCoinSelector` | class | Minimises change output |
| `MinimizeInputsCoinSelector` | class | Minimises number of inputs |
| `SmallestSingleCoinSelector` | class | Smallest qualifying single UTXO |
| `BranchAndBoundCoinSelector` | class | Bitcoin Core-style changeless search |
| `KnapsackCoinSelector` | class | Stochastic subset-sum selector |
| `SingleRandomDrawCoinSelector` | class | Randomised UTXO selection |
| `TransactionSigner` | abstract class | Signs a prepared transaction |

### Domain value objects

| Symbol | Kind | Description |
|---|---|---|
| `CoinCandidate` | class | A UTXO candidate for coin selection |
| `CoinSelectionResult` | class | Output of a coin selection run |
| `CoinSelectionStrategyResult` | class | Strategy result with display metadata |
| `ScriptType` | enum | P2PKH / P2SH / P2WPKH / P2WSH / P2TR / OP_RETURN / UNKNOWN |
| `SigningInput` | class | Input descriptor for HD transaction signing |
| `TxOutput` | sealed class | Typed output: `AddressOutput` or `OpReturnOutput` |

### Assembly

| Symbol | Kind | Description |
|---|---|---|
| `TransactionAssembly` | final class | DI factory; exposes repos, gateways, and use cases |

## Dependencies

Workspace packages: `shared_kernel`, `wallet`.
Third-party: none.
SDK: Dart SDK only.

## When to add here

Add a symbol when it is a transaction or UTXO entity, a repository or gateway
contract, a use case that builds or queries transactions, or a coin-selection /
fee-estimation / script service. Never add wallet or address entities here.

## Layer layout

```
lib/
  transaction.dart              # public barrel
  transaction_assembly.dart     # DI factory
  src/
    application/
      hd/
        hd_send_preparation.dart
        hd_send_workflow.dart
        prepare_hd_send_use_case.dart
        send_hd_transaction_use_case.dart
      node/
        node_send_preparation.dart
        node_send_workflow.dart
        prepare_node_send_use_case.dart
        send_node_transaction_use_case.dart
        send_op_return_use_case.dart
      send_preparation.dart
      send_workflow.dart
    data/
      repository/
        transaction_repository_impl.dart
        utxo_repository_impl.dart
    domain/
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
        transaction_exception.dart
        coin_selection_no_solution_exception.dart
      gateway/
        block_generation_gateway.dart
        broadcast_gateway.dart
        node_transaction_gateway.dart
        transaction_history_gateway.dart
        utxo_gateway.dart
        utxo_scan_gateway.dart
      repository/
        transaction_repository.dart
        utxo_repository.dart
      service/
        branch_and_bound_coin_selector.dart
        coin_selection_recommender.dart
        coin_selection_request.dart
        coin_selector.dart
        coin_selector_base.dart
        eligibility_policy.dart
        fee_estimator.dart
        fifo_coin_selector.dart
        knapsack_coin_selector.dart
        lifo_coin_selector.dart
        minimize_change_coin_selector.dart
        minimize_inputs_coin_selector.dart
        op_return_script_builder.dart
        script_classifier.dart
        script_decoder.dart
        single_random_draw_coin_selector.dart
        smallest_single_coin_selector.dart
        transaction_signer.dart
        utxo_eligibility_filter.dart
      value_object/
        coin_candidate.dart
        coin_selection_result.dart
        coin_selection_strategy_result.dart
        script_type.dart
        signing_input.dart
        tx_output.dart
```
