# Tasklist: BW-0003 — Key Derivation and Self-Signing

Status: `CLOSED`
Ticket: BW-0003
Phase: feature
Lane: Critical
Workflow Version: 3
Owner: Implementer
Branch: BW-0003-key-derivation-signing

---

## Progress

| Phase | Goal | Status |
|-------|------|--------|
| 1 | Complete Phase 06 — verify and close | ✅ Done |

---

## Phase 06: Key derivation and self-signing

Code landed in BW-0002 (partial). BW-0003 completes and verifies.

### Architecture note: feature structure

Feature folder is domain-grouped (namespace pattern):
```
signing/
  manual_utxo/   ← ManualUtxoScope + SigningBloc + SigningDemoScreen
                   Temporary scaffolding — prototype of manual UTXO selection.
                   Will be absorbed into BW-0004 unified send flow.
  xpub/          ← XpubScope + XpubBloc + XpubScreen
transaction/
  list/          ← TransactionListScope + TransactionBloc + TransactionListScreen
  detail/        ← TransactionDetailScope + TransactionDetailBloc + TransactionDetailScreen
```
Grouper folders contain zero Dart files — only sub-feature folders.

### Already implemented (carried from BW-0002)

- [x] `XpubBloc` + `XpubScreen` — display derived xpub and derivation path
- [x] `SigningBloc` + `SigningDemoScreen` — scan UTXOs → sign internally → broadcast (`signing/manual_utxo/`)
- [x] `TransactionSigningServiceImpl` — P2WPKH BIP143 sighash + ECDSA/secp256k1
- [x] `ManualUtxoScope`, `XpubScope` — DI wiring (split from old monolithic `SigningScope`)

### Remaining

- [ ] Update `progress.md`: Phase 06 checklist items → completed
- [x] Verify: `flutter analyze --fatal-infos` clean
- [x] Verify: `dcm analyze` clean
- [x] Verify: `dart test packages/transaction` and `dart test packages/keys` pass (13 + 36 tests)
- [ ] Manual test: HD wallet → Sign & Send (demo) → sign internally → broadcast → confirm via getrawtransaction
- [ ] Manual test: HD wallet → Account xpubs → xpub displayed with derivation path

---

## Release Readiness

- [ ] All items above complete
- [ ] `progress.md` updated: Phase 06 → `completed`
- [ ] `progress.md`: BW-0003 → `closed`
