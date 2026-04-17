# Tasklist: BW-0002 — Transaction History + UTXO Inspection

Status: `TASKLIST_READY`
Ticket: BW-0002
Phase: feature
Lane: Professional
Workflow Version: 3
Owner: Planner
Context: Idea `docs/BW-0002/idea-BW-0002.md` · Vision `docs/BW-0002/vision-BW-0002.md`

---

## Progress

| Phase | Goal | Status | Review | Security | QA |
|-------|------|--------|--------|----------|----|
| 1 | Domain entities + RPC layer | ⬜ Pending | - | n/a | - |
| 2 | BLoC + screens | ⬜ Pending | - | n/a | - |
| 3 | Navigation + integration | ⬜ Pending | - | n/a | - |

---

## Phase Breakdown

### Phase 1: Domain entities + RPC layer

Build the data model and adapter so the app can fetch transaction and UTXO data from Bitcoin Core.

Tasks:
- [ ] 1.1 Create `packages/transaction/` with pubspec.yaml (depends: shared_kernel, wallet, address)
- [ ] 1.2 Create domain entities: `Transaction`, `TransactionInput`, `TransactionOutput`, `Utxo`
- [ ] 1.3 Create repository interfaces: `TransactionRepository`, `UtxoRepository`
- [ ] 1.4 Create ISP data source interface: `TransactionRemoteDataSource` (listtransactions, gettransaction, listunspent, gettxout)
- [ ] 1.5 Implement `TransactionRemoteDataSourceImpl` in `packages/bitcoin_node/`
- [ ] 1.6 Implement `TransactionRepositoryImpl` and `UtxoRepositoryImpl`
- [ ] 1.7 Create `TransactionAssembly` and `UtxoAssembly` DI factories
- [ ] 1.8 Update `AppDependencies` and `AppDependenciesBuilder` to wire transaction/utxo assemblies
- [ ] 1.9 Unit tests for domain entities
- [ ] 1.10 Verify: `flutter analyze --fatal-infos` and `dcm analyze` clean

Exit criteria:
- `packages/transaction/` is a complete domain module with repositories, entities, use cases
- RPC layer fetches live transaction and UTXO data from regtest node
- All imports from old domain/data packages are removed
- Analyzer clean

---

### Phase 2: BLoC + screens

Build the state management and UI to display transaction and UTXO data.

Tasks:
- [ ] 2.1 Create `TransactionBloc` (events: fetch, refresh; state: list, loading, error)
- [ ] 2.2 Create `TransactionListScreen` with list of transactions (direction, amount, confs)
- [ ] 2.3 Create `TransactionDetailScreen` with full tx data (inputs, outputs, fee, hex)
- [ ] 2.4 Create `UtxoBloc` (events: fetch, refresh; state: list, loading, error)
- [ ] 2.5 Create `UtxoListScreen` with list of UTXOs (amount, confs, address, script type)
- [ ] 2.6 Create `UtxoDetailScreen` with raw script and derivation path
- [ ] 2.7 Implement mempool vs confirmed visual distinction (color, badge, or icon)
- [ ] 2.8 Verify: `flutter analyze --fatal-infos` and `dcm analyze` clean

Exit criteria:
- All screens render live data from regtest node
- Navigation between list and detail works smoothly
- Mempool state is visually distinct
- No lint errors

---

### Phase 3: Navigation + integration

Wire the new screens into the wallet detail flow.

Tasks:
- [ ] 3.1 Add navigation from `WalletDetailScreen` to `TransactionListScreen`
- [ ] 3.2 Add navigation from `WalletDetailScreen` to `UtxoListScreen`
- [ ] 3.3 Add tap-to-detail for both screens
- [ ] 3.4 Refresh transaction/UTXO data when screens are opened (onInit or didChangeDependencies)
- [ ] 3.5 Add copy-to-clipboard for txid, address, raw hex
- [ ] 3.6 Update `progress.md`: Phase 04 → `completed`
- [ ] 3.7 End-to-end test: create wallet → receive coins → observe in tx/utxo lists
- [ ] 3.8 Verify: `flutter analyze --fatal-infos`, `dcm analyze`, `dart test packages/transaction` clean

Exit criteria:
- User can navigate from wallet detail → tx list → tx detail and back
- User can navigate from wallet detail → utxo list → utxo detail and back
- All data is live from Bitcoin Core
- No lint errors, all tests pass
- `progress.md` updated

---

## Release Readiness

- [ ] All 3 phases complete
- [ ] All review summaries present
- [ ] All QA records passed
- [ ] Validator clean
- [ ] `docs/project/architecture.md` updated (if needed)
- [ ] `progress.md` updated: Phase 04 → `completed`
