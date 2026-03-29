# ADR-001: Use coinlib for BIP39/32/44/49/84/86 Key Derivation

Status: `SUPERSEDED` by manual implementation decision (see research/BW-0001-phase-1.md)
Date: 2026-03-26
Deciders: Project owner

---

## Context

FEAT-001 requires BIP39 mnemonic generation, BIP32 HD key derivation, and address encoding
for all four script types (P2PKH, P2SH-P2WPKH, P2WPKH, P2TR) on regtest.
The library must support all target platforms: iOS, Android, macOS, Windows, Linux, Web.

---

## Decision

Use **`coinlib: 2.2.0`**.

---

## Alternatives Considered

| Package | Version | Reason Rejected |
|---------|---------|----------------|
| `bip39` | 1.0.6 | BIP39 only — no key derivation or address encoding |
| `bitcoin_flutter` | 0.0.6 | BIP32 only, outdated, no Taproot (BIP86) |
| `hdwallet` | 1.5.0 | BIP44/49/84 only — no Taproot; limited platform support |
| `coinlib` | 2.2.0 | ✅ Selected |

---

## Rationale

`coinlib` is the only active Dart library that provides:
- BIP39 mnemonic generation and validation
- BIP32 HD key derivation
- Address encoding for all four types: P2PKH, P2SH-P2WPKH, P2WPKH (bech32), P2TR (bech32m)
- Configurable network parameters — supports regtest (`coin_type=1`, `bcrt` HRP)
- Full platform support: iOS, Android, macOS, Windows, Linux, Web

---

## Consequences

**Positive:**
- Single dependency for all Bitcoin cryptography needs
- Active maintenance and Taproot support
- Regtest compatibility verified (task 3.3)

**Negative:**
- Less widely used than `bitcoin_flutter` — fewer community examples
- Regtest address correctness must be verified in phase 3

---

## Verification

Task 3.3 (address verification via Bitcoin Core `deriveaddresses` RPC) confirms
that `coinlib` produces correct regtest addresses before phase 4 proceeds.
