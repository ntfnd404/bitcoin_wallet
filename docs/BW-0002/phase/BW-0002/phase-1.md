# Phase 1: Domain entities + RPC layer

Status: `TASKLIST_READY`
Ticket: BW-0002
Phase: 1
Lane: Professional
Workflow Version: 3
Owner: Implementer
Goal: Build the data model and RPC adapter so the app can fetch live transaction and UTXO data from Bitcoin Core

Session brief — execution packet only. Do not repeat full architecture rationale here.

---

## Current Batch

Implementer will:

1. Create new domain module `packages/transaction/` with entities (Transaction, TransactionInput, TransactionOutput, Utxo)
2. Define repository and data source interfaces
3. Implement RPC adapter in `packages/bitcoin_node/`
4. Wire into AppDependencies

After Phase 1, the app has live tx/utxo data but no UI. Phase 2 builds BLoCs and screens.

---

## Constraints

- Domain package must be pure Dart (no Flutter dependency) — only depend on shared_kernel, wallet, address
- Use ISP (Interface Segregation Principle): `TransactionRemoteDataSource` interface owned by transaction package; adapter implements it
- Follow existing Assembly pattern for DI factory
- No old `package:domain/` or `package:data/` imports allowed — migrate to new modules only
- All entities must be immutable (final class with const constructor)
- Entity field names must match Bitcoin Core RPC field names for clarity (txid, vout, scriptPubKey, etc.)

---

## Execution Checklist

- [ ] 1.1 Create packages/transaction/ with pubspec.yaml (depends: shared_kernel, wallet, address)
- [ ] 1.2 Create domain/entity/: Transaction.dart, TransactionInput.dart, TransactionOutput.dart, Utxo.dart
- [ ] 1.3 Create domain/repository/: TransactionRepository.dart, UtxoRepository.dart (interfaces)
- [ ] 1.4 Create domain/data_sources/: TransactionRemoteDataSource.dart (ISP interface: listtransactions, gettransaction, listunspent, gettxout)
- [ ] 1.5 Create data layer: transaction_repository_impl.dart, utxo_repository_impl.dart
- [ ] 1.6 Create application layer: get_transactions_use_case.dart, get_utxos_use_case.dart (optional for Phase 1; may defer to Phase 2)
- [ ] 1.7 Create packages/bitcoin_node/ adapter: TransactionRemoteDataSourceImpl (implements TransactionRemoteDataSource)
- [ ] 1.8 Create transaction_assembly.dart and utxo_assembly.dart DI factories
- [ ] 1.9 Create transaction.dart barrel (public API)
- [ ] 1.10 Update lib/core/di/: AppDependencies + AppDependenciesBuilder to hold transaction/utxo assemblies
- [ ] 1.11 Write unit tests for domain entities (immutability, validation)
- [ ] 1.12 Run flutter analyze --fatal-infos → must pass clean
- [ ] 1.13 Run dcm analyze → must pass clean

---

## Stop Conditions

- architecture deviation (e.g., breaking ISP, allowing Flutter in domain)
- blocker (e.g., RPC method contract differs from expected)
- risk discovery (e.g., major performance issue with data fetching)
- batch complete (all checklist items done, all checks pass)

---

## Acceptance

Phase 1 is complete when:
- `packages/transaction/` is a fully layered domain module (domain/, application/, data/)
- `TransactionRemoteDataSourceImpl` in `packages/bitcoin_node/` successfully calls Bitcoin Core RPC methods
- `AppDependencies` holds transaction and utxo assemblies
- `flutter analyze --fatal-infos` and `dcm analyze` pass clean
- Unit tests for domain entities run and pass
- No old `package:domain/` or `package:data/` imports remain in transaction module
