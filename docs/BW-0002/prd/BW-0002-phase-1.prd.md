# BW-0002 Phase 1 PRD — Domain entities + RPC layer

Status: `PRD_READY`
Ticket: BW-0002
Phase: 1
Lane: Professional
Workflow Version: 3
Owner: Analyst

---

## Phase Intent

Establish the data model and RPC contract so the app can fetch and represent Bitcoin Core wallet state (transactions and UTXOs). Phase 1 is foundational: without it, Phase 2 (UI) has nothing to display.

---

## Deliverables

1. **`packages/transaction/` domain module** — complete layered package with entities, repositories, interfaces
   - Domain entities: Transaction, Utxo (immutable value objects matching Bitcoin Core field names)
   - Repository interfaces defining contracts for fetching txs and UTXOs
   - ISP data source interface (TransactionRemoteDataSource) with RPC method signatures

2. **RPC adapter: `TransactionRemoteDataSourceImpl`** in packages/bitcoin_node/
   - Calls `listtransactions`, `gettransaction`, `listunspent`, `gettxout` on Bitcoin Core
   - Maps RPC responses to domain entity data transfer objects
   - Handles errors and edge cases (missing fields, script types, etc.)

3. **DI wiring** in app layer
   - `TransactionAssembly` and `UtxoAssembly` factories
   - Updated `AppDependencies` and `AppDependenciesBuilder`

4. **Unit tests**
   - Domain entity construction, validation, immutability
   - No integration tests in Phase 1 (defer to Phase 3 end-to-end)

---

## Scenarios

### Positive

**Scenario: Fetch transactions for a wallet with on-chain history**

1. App requests transaction list for walletId "123"
2. `TransactionRepository.getTransactions()` calls remote data source
3. Remote data source calls `listtransactions` on Bitcoin Core for the wallet
4. RPC returns array of tx objects (txid, confirmations, amount, category: receive|send|generate, etc.)
5. Adapter maps each to `Transaction` entity
6. App receives `List<Transaction>` with correct direction, amount, confirmations
7. Caller can display txs in a list screen (Phase 2)

**Scenario: Fetch UTXOs for coin selection or inspection**

1. App requests UTXO list for walletId "123"
2. `UtxoRepository.getUtxos()` calls remote data source
3. Remote data source calls `listunspent` on Bitcoin Core
4. RPC returns array of { txid, vout, amount, confirmations, address, scriptPubKey, ... }
5. Adapter enriches with AddressType (P2PKH, P2WPKH, etc.) by parsing scriptPubKey
6. App receives `List<Utxo>`
7. Caller can display in a list or use for coin selection (Phase 5)

### Negative / Edge

**Scenario: Empty transaction history**

1. App requests txs for a newly created wallet with no activity
2. `listtransactions` returns empty array
3. App displays "No transactions yet"

**Scenario: Mempool vs confirmed**

1. Wallet has pending (unconfirmed) transactions
2. `listtransactions` returns txs with confirmations=0
3. Adapter marks as isMempool=true
4. UI can distinguish visually (color, badge)

**Scenario: OP_RETURN output (no address)**

1. `listunspent` includes a UTXO with scriptPubKey="6a20..." (OP_RETURN)
2. Adapter detects script type and marks address as "(OP_RETURN)" or null
3. App displays gracefully without crashing

**Scenario: Coinbase transaction (no inputs)**

1. Regtest generates a block with a coinbase tx
2. `gettransaction` returns tx with empty inputs array
3. Adapter handles empty inputs list without error
4. App displays "Coinbase" or similar

---

## Success Metrics

| Criterion | Verification |
|-----------|--------------|
| Transaction entities are immutable and const-constructible | Code review: all fields final, constructor const |
| RPC adapter calls correct Bitcoin Core methods | Code review + manual test: invoke adapter, log RPC calls, verify method names |
| Transaction data matches RPC response fields | Integration test: fetch from regtest, compare fields (txid, amount, confs) |
| UTXO script types are correctly identified | Unit test: map scriptPubKey bytes to AddressType enum |
| No old domain/data package imports | Grep clean: zero matches for `package:domain/` and `package:data/` in transaction module |
| Analyzer and DCM pass | CI: `flutter analyze --fatal-infos` and `dcm analyze` clean |
| Unit tests pass | CI: `dart test packages/transaction` 100% pass rate |

---

## Constraints

- Domain package must be pure Dart — only depend on shared_kernel, wallet, address (no Flutter, no observability in Phase 1)
- ISP: TransactionRemoteDataSource interface owned by transaction module; no coupling to Bitcoin Core types
- Entities must match Bitcoin Core field names for clarity (txid not transaction_id, vout not output_index, etc.)
- No premature optimization: use simple List instead of pagination or virtualization in Phase 1
- All RPC field mappings must be documented in comments (Bitcoin Core RPC field → entity field)

---

## Out Of Scope

- Broadcasting transactions (Phase 05)
- Script decoding / custom script scenarios (Phase 07)
- Fee estimation (defer to Phase 05)
- Address labeling (used vs unused) — Phase 03 remainder
- Pagination or virtualization of large tx/utxo lists (Phase 2 can add if needed)
- Caching strategy (Phase 2 can optimize if needed)
- Push notifications for incoming transactions
- Mempool fee estimation

---

## Open Questions

- [ ] Should TransactionRemoteDataSource include a method to fetch a single tx detail (gettransaction), or is listtransactions sufficient? **Answer: Include gettransaction for Phase 2 detail screen.**
- [ ] How does derivation path get added to Utxo entities? Bitcoin Core does not return derivation path in listunspent. **Answer: Phase 1 leaves as null or placeholder; Phase 2/3 can compute from address and key derivation state if needed.**
- [ ] Should we fetch full tx details (inputs, outputs, fee) in Phase 1, or defer to Phase 2? **Answer: Phase 1 keeps domain model simple; Phase 2 adds TransactionDetail entity if needed.**
