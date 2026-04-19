# Tasklist: BW-0003 — Key Derivation and Self-Signing

Status: `IN_PROGRESS`
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
| 1 | Complete Phase 06 — verify and close | 🔄 In progress |

---

## Phase 06: Key derivation and self-signing

Code landed in BW-0002 (partial). BW-0003 completes and verifies.

### Already implemented (carried from BW-0002)

- [x] `XpubBloc` + `XpubScreen` — display derived xpub and derivation path
- [x] `SigningBloc` + `SigningDemoScreen` — scan UTXOs → sign internally → broadcast
- [x] `TransactionSigningServiceImpl` — P2WPKH BIP143 sighash + ECDSA/secp256k1
- [x] `SigningScope` — DI wiring

### Remaining

- [ ] Update `progress.md`: Phase 06 checklist items → completed
- [ ] Verify: `flutter analyze --fatal-infos` clean
- [ ] Verify: `dcm analyze` clean
- [ ] Verify: `dart test packages/transaction` and `dart test packages/keys` pass
- [ ] Manual test: HD wallet → Sign & Send (demo) → sign internally → broadcast → confirm via getrawtransaction
- [ ] Manual test: HD wallet → Account xpubs → xpub displayed with derivation path

---

## Release Readiness

- [ ] All items above complete
- [ ] `progress.md` updated: Phase 06 → `completed`
- [ ] `progress.md`: BW-0003 → `closed`
