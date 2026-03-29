# QA: FEAT-001 Final — Wallet Creation, Address Generation, Seed Phrase

Status: `PENDING` — to be filled after all phases complete and REVIEW_OK

---

## Positive Scenarios (PS)

- [ ] PS-1: Node Wallet created via RPC — wallet appears in `listwallets`
- [ ] PS-2: HD Wallet created — mnemonic displayed, confirmation required before proceeding
- [ ] PS-3: HD Wallet restored — same seed produces identical addresses
- [ ] PS-4: All four address types generated for Node Wallet (Legacy, Wrapped SegWit, Native SegWit, Taproot)
- [ ] PS-5: All four address types generated for HD Wallet with correct derivation paths
- [ ] PS-6: Seed phrase viewable from wallet settings after initial creation
- [ ] PS-7: Wallet list shows all wallets with correct type labels
- [ ] PS-8: QR code renders and is scannable by a standard Bitcoin QR reader
- [ ] PS-9: Address copy button works on macOS

## Negative / Edge Cases (NE)

- [ ] NE-1: Invalid BIP39 mnemonic on restore → shows validation error, no crash
- [ ] NE-2: Bitcoin Core node unreachable → shows error state, not blank screen
- [ ] NE-3: Empty wallet name → create button disabled
- [ ] NE-4: Restoring with 11 words → BIP39 validation rejects immediately

## Bitcoin-Specific Checks (BC)

- [ ] BC-1: Legacy address starts with `m`
- [ ] BC-2: Wrapped SegWit address starts with `2`
- [ ] BC-3: Native SegWit address starts with `bcrt1q`
- [ ] BC-4: Taproot address starts with `bcrt1p`
- [ ] BC-5: HD derivation deterministic — same seed → same addresses on re-import
- [ ] BC-6: BIP39 checksum validated on restore input

## Implementation Verification (IV)

- [ ] IV-1: `flutter analyze` — zero warnings/errors
- [ ] IV-2: Seed phrase not visible in any logs
- [ ] IV-3: Seed phrase not stored in SharedPreferences (only in SecureStorage)
- [ ] IV-4: Private keys do not appear in UI layer or logs
- [ ] IV-5: On Web: warning shown about unencrypted localStorage

## Manual Checks (MC)

- [ ] MC-1: App launches on macOS without errors
- [ ] MC-2: Navigation works without errors (no missing routes)
- [ ] MC-3: All screens render without overflow or layout errors

## Verdict

`PENDING`
