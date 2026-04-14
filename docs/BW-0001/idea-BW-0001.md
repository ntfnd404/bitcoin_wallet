# Idea: Wallet Creation, Address Generation, Seed Phrase (BW-0001)

Status: `IDEA_READY`
Date: 2026-03-26

---

## Problem

The app needs a working Flutter layer on top of the Bitcoin Core regtest node.
Currently `lib/main.dart` is a Hello World — no wallets, no addresses, no key management.

Two fundamentally different wallet models must coexist in a single app:
- **Node Wallet** — Bitcoin Core holds keys; Flutter is a UI over RPC (custodial).
- **HD Wallet** — BIP39 mnemonic lives in the app; keys never leave the device (non-custodial).

---

## Goal

Demonstrate the custodial vs non-custodial split, implement BIP39/32/44/49/84/86 key derivation
natively in Flutter, support all four Bitcoin address types, store seed phrase securely,
and allow wallet restore.

---

## User Stories

### Wallet creation

- As a user, I want to choose a wallet type (Node Wallet or HD Wallet)
  so that I understand the difference between custodial and non-custodial.
- As a user, I want to create a Node Wallet backed by Bitcoin Core RPC.
- As a user, I want to create an HD Wallet and receive a seed phrase so that I control my own keys.

### Seed phrase

- As a user, I want to see my 12- or 24-word BIP39 mnemonic when creating an HD wallet.
- As a user, I must confirm I have saved the seed phrase before proceeding.
- As a user, I want to restore an HD Wallet from a seed phrase (determinism verification).
- As a user, I want to view my seed phrase at any time from wallet settings.

### Addresses

- As a user, I want all four address types: Legacy, Wrapped SegWit, Native SegWit, Taproot.
- As a user, I want to generate an address of any type and see it as text + QR code.
- As a user, I want to see the derivation path for each HD Wallet address.

---

## Requirements

### R1. Wallet types

| # | Requirement |
|---|-------------|
| R1.1 | App offers choice: Node Wallet or HD Wallet |
| R1.2 | Node Wallet created via Bitcoin Core RPC `createwallet` |
| R1.3 | HD Wallet generates BIP39 mnemonic locally in Flutter |
| R1.4 | Both types support all four address types |
| R1.5 | UI explains custodial vs non-custodial difference |

### R2. Seed phrase (HD Wallet only)

| # | Requirement |
|---|-------------|
| R2.1 | Generate BIP39 mnemonic (12 or 24 words) |
| R2.2 | Seed phrase shown before navigating to wallet |
| R2.3 | User must confirm seed phrase saved |
| R2.4 | Seed phrase stored in `flutter_secure_storage` |
| R2.5 | HD Wallet restore with BIP39 checksum validation |
| R2.6 | Seed phrase accessible from wallet settings (with confirmation) |
| R2.7 | Seed phrase never logged, never leaves device |

### R3. Addresses

| # | Requirement |
|---|-------------|
| R3.1 | P2PKH (Legacy), path `m/44'/1'/0'/0/n` |
| R3.2 | P2SH-P2WPKH (Wrapped SegWit), path `m/49'/1'/0'/0/n` |
| R3.3 | P2WPKH (Native SegWit / Bech32), path `m/84'/1'/0'/0/n` |
| R3.4 | P2TR (Taproot / Bech32m), path `m/86'/1'/0'/0/n` |
| R3.5 | Address as text with copy button |
| R3.6 | Address as QR code |
| R3.7 | Derivation path shown for HD Wallet addresses |
| R3.8 | Regtest prefixes: Legacy=`m`, P2SH=`2`, Bech32=`bcrt1q`, Bech32m=`bcrt1p` |

### R4. Wallet list

| # | Requirement |
|---|-------------|
| R4.1 | Screen listing all wallets with type label (Node / HD) |
| R4.2 | Navigate to wallet detail (addresses, seed) |

---

## Acceptance Criteria

| Criterion | Verification |
|-----------|--------------|
| BIP39 seed restores identical addresses | 100% match on re-import |
| Addresses match derivation path | Verified against Bitcoin Core `deriveaddresses` |
| Seed stored in secure storage | Not visible as plaintext via storage inspection |
| QR code is scannable | Any standard Bitcoin QR reader |
| App runs on macOS (primary dev platform) | Manual test |

---

## Constraints

- Regtest only (`coin_type = 1` in derivation paths)
- No watch-only (xpub-only) wallet — out of scope
- No multisig — out of scope
- Node Wallet: Bitcoin Core holds keys, Flutter never sees them
- HD Wallet: private keys must not leave the data/domain layer

---

## Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Dart BIP library does not support regtest | Medium | Verify coin_type=1 and prefix before committing |
| Taproot derivation (BIP86/340) more complex | High | Separate task, unit test against Bitcoin Core |
| `flutter_secure_storage` on Linux/Web | Low | Add fallback or warning if needed |
