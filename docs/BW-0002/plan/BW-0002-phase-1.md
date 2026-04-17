# Plan: BW-0002 Phase 1 — Domain entities + RPC layer

Status: `PLAN_APPROVED`
Ticket: BW-0002
Phase: 1
Lane: Professional
Workflow Version: 3
Owner: Planner / Architect

---

## Phase Scope

Build the data layer so the app can fetch transaction and UTXO data from Bitcoin Core regtest. After Phase 1, the app has the domain model and RPC adapter; Phase 2 will build BLoCs and UI.

---

## File Changes

| File / Directory | Change | Why |
|------|--------|-----|
| `packages/transaction/pubspec.yaml` | Create new | New domain module |
| `packages/transaction/lib/transaction.dart` | Create new | Barrel (public API) |
| `packages/transaction/lib/transaction_assembly.dart` | Create new | DI factory |
| `packages/transaction/lib/src/domain/entity/transaction.dart` | Create new | Transaction entity with txid, direction, amount, confirmations, timestamp |
| `packages/transaction/lib/src/domain/entity/transaction_input.dart` | Create new | Input entity: txid, vout, scriptSig |
| `packages/transaction/lib/src/domain/entity/transaction_output.dart` | Create new | Output entity: address, amount, scriptPubKey |
| `packages/transaction/lib/src/domain/entity/utxo.dart` | Create new | UTXO entity: txid, vout, amount, confirmations, address, scriptPubKey, derivation path |
| `packages/transaction/lib/src/domain/repository/transaction_repository.dart` | Create new | Interface: getTransactions(walletId) |
| `packages/transaction/lib/src/domain/repository/utxo_repository.dart` | Create new | Interface: getUtxos(walletId) |
| `packages/transaction/lib/src/domain/data_sources/transaction_remote_data_source.dart` | Create new | ISP interface: listtransactions, gettransaction, listunspent, gettxout |
| `packages/transaction/lib/src/data/transaction_repository_impl.dart` | Create new | Implements TransactionRepository; calls remote data source |
| `packages/transaction/lib/src/data/utxo_repository_impl.dart` | Create new | Implements UtxoRepository; calls remote data source |
| `packages/bitcoin_node/lib/src/transaction_remote_data_source_impl.dart` | Create new | Implements TransactionRemoteDataSource; calls BitcoinRpcClient |
| `packages/bitcoin_node/lib/bitcoin_node.dart` | Update | Add export of TransactionRemoteDataSourceImpl |
| `lib/core/di/app_dependencies.dart` | Update | Add TransactionAssembly, UtxoAssembly fields |
| `lib/core/di/app_dependencies_builder.dart` | Update | Wire transaction and utxo assemblies; create remote data sources |

---

## Interfaces And Contracts

```dart
// packages/transaction/lib/src/domain/entity/transaction.dart
final class Transaction {
  final String txid;
  final TransactionDirection direction; // enum: incoming, outgoing, self
  final BigInt amount; // in satoshis
  final int confirmations;
  final DateTime timestamp;
  final bool isMempool; // true if confirmations < 1
}

// packages/transaction/lib/src/domain/entity/utxo.dart
final class Utxo {
  final String txid;
  final int vout;
  final BigInt amount;
  final int confirmations;
  final String address;
  final String scriptPubKey; // raw hex
  final AddressType type; // P2PKH, P2WPKH, P2SH, P2TR, unknown
  final String derivationPath; // m/44h/1h/0h/0/N or similar
}

// packages/transaction/lib/src/domain/data_sources/transaction_remote_data_source.dart
abstract interface class TransactionRemoteDataSource {
  /// Fetch wallet transactions. If mempool=true, include unconfirmed.
  Future<List<TransactionData>> listtransactions(String walletName, {bool mempool = true});
  
  /// Fetch details of a single transaction.
  Future<TransactionDetailData> gettransaction(String txid);
  
  /// List unspent outputs for the wallet.
  Future<List<UtxoData>> listunspent(String walletName);
  
  /// Get details of a single output.
  Future<UtxoDetailData> gettxout(String txid, int vout);
}

// packages/bitcoin_node/lib/src/transaction_remote_data_source_impl.dart
final class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final BitcoinRpcClient _rpcClient;
  
  const TransactionRemoteDataSourceImpl({required BitcoinRpcClient rpcClient})
    : _rpcClient = rpcClient;
  
  @override
  Future<List<TransactionData>> listtransactions(String walletName, {bool mempool = true}) async {
    final result = await _rpcClient.call('listtransactions', ['*', 100, 0], walletName);
    // Map result to List<TransactionData>
  }
  
  // ... other methods
}
```

---

## Sequencing

1. Create `packages/transaction/` directory and pubspec.yaml
2. Create domain entities (Transaction, TransactionInput, TransactionOutput, Utxo) — value objects, immutable
3. Create domain repository interfaces (TransactionRepository, UtxoRepository)
4. Create domain data source interface (TransactionRemoteDataSource) with RPC method signatures
5. Implement data layer (repositories) — simple adapters between remote data source and domain entities
6. Implement RPC adapter in `packages/bitcoin_node/` — call BitcoinRpcClient, parse responses into DTOs
7. Create Assembly DI factories for transaction and utxo modules
8. Update AppDependencies and AppDependenciesBuilder to wire assemblies
9. Write unit tests for domain entities
10. Run analyzer and DCM — must be clean

---

## Error Handling And Edge Cases

- If a transaction has no inputs (coinbase txn) — handle gracefully, empty input list
- If `gettransaction` returns "tx not in mempool" error — may need to use `getrawtransaction` with `verbose=true` instead
- If a UTXO has no address field (OP_RETURN output) — use placeholder "OP_RETURN" or "(no address)"
- If confirmation count is -1 (conflict in mempool) — display as mempool state

---

## Checks

- `flutter analyze --fatal-infos` — must pass clean
- `dcm analyze` — must pass clean
- `dart test packages/transaction` — all tests pass (unit tests for entities)
- `grep -r "package:domain/" packages/transaction/ lib/` — must return nothing
- `grep -r "package:data/" packages/transaction/ lib/` — must return nothing

---

## Risks

- BitcoinRpcClient response format differs from expected (e.g., field name changes between Bitcoin Core versions) — mitigated by pinning Bitcoin Core version in docker/bitcoin.conf and testing against it
- Large UTXO list (1000+ outputs) may cause memory issues or slow rendering — Phase 1 does not paginate; Phase 2 can add virtualization if needed
- Derivation path not available from Bitcoin Core RPC — may need to compute it from address and key derivation state (deferred to Phase 2 if needed)
- Transaction parsing fails if script format is unknown — use fallback "unknown script" label
