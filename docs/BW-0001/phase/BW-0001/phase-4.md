# Phase 4: Data — HD Wallet & Key Derivation

Status: `PLAN_APPROVED`
Ticket: BW-0001

---

## Goal

Implement BIP39 mnemonic generation/validation, BIP32 key derivation for all 4 address
types, seed persistence, and the HD Wallet repository.

---

## Context

Phase 3 delivered `NodeWalletRepositoryImpl` and the `WalletLocalStore` pattern.
Phase 4 completes the data layer — after this phase, both wallet types are fully functional.

This is the most crypto-heavy phase. All BIP39/BIP32/address encoding is implemented
manually using `crypto` + `pointycastle` (project convention: no high-level Bitcoin library).

After Phase 4:
- `AppDependenciesBuilder` wires all real implementations (no more stubs except UI-facing)
- BLoC (Phase 5) can call any repository/service method

---

## Tasks

- [x] **4.1** `Bip39ServiceImpl` — generate + validate BIP39 mnemonics (12/24 words)
- [x] **4.2** `KeyDerivationServiceImpl` — BIP32 derivation + 4 address types
- [ ] **4.3** `SeedRepositoryImpl` — store/retrieve/delete mnemonic via SecureStorage
- [ ] **4.4** `HdWalletRepositoryImpl` — orchestrate BIP39 + derivation + persistence

---

## Acceptance Criteria

- Generated 12-word mnemonic passes BIP39 validation
- Generated 24-word mnemonic passes BIP39 validation
- Invalid mnemonic fails validation
- `deriveAddress(mnemonic, nativeSegwit, 0)` → deterministic `bcrt1q...` address
- Same mnemonic + same index → identical address (deterministic)
- Restored wallet generates same addresses as original
- Seed stored in SecureStorage, retrievable after "restart" (re-read)
- Regtest prefixes: legacy=`m`/`n`, wrapped=`2`, native=`bcrt1q`, taproot=`bcrt1p`
- `flutter analyze` — zero warnings
- Unit tests pass without regtest node

---

## Dependencies

- Phase 2: domain interfaces (`Bip39Service`, `KeyDerivationService`, `SeedRepository`, `HdWalletRepository`)
- Phase 3: `WalletLocalStore`, `SecureStorage` interface
- Packages: `crypto: 3.0.7`, `pointycastle: 4.0.0`

---

## Technical Details

### BIP39 — Mnemonic generation

1. Generate 128 bits (12 words) or 256 bits (24 words) of entropy via `SecureRandom`
2. SHA256 hash of entropy → take first `entropy_bits / 32` bits as checksum
3. Concatenate entropy + checksum → split into 11-bit groups
4. Map each 11-bit value to BIP39 English wordlist index

### BIP39 → Seed

PBKDF2-HMAC-SHA512:
- Password: mnemonic sentence (words joined by space)
- Salt: `"mnemonic"` + passphrase (empty string for us)
- Iterations: 2048
- Output: 64 bytes (512 bits)

### BIP32 — HD key derivation

Master key: HMAC-SHA512 with key `"Bitcoin seed"` and data = seed bytes.
- Left 32 bytes = master private key
- Right 32 bytes = master chain code

Child derivation (hardened): `HMAC-SHA512(chainCode, 0x00 || key || index_with_0x80000000)`

Derivation paths (regtest, coin_type=1):
- Legacy: `m/44'/1'/0'/0/<index>`
- Wrapped SegWit: `m/49'/1'/0'/0/<index>`
- Native SegWit: `m/84'/1'/0'/0/<index>`
- Taproot: `m/86'/1'/0'/0/<index>`

### Address encoding

| Type | Script | Encoding | Prefix (regtest) |
|------|--------|----------|------------------|
| P2PKH | `OP_DUP OP_HASH160 <hash> OP_EQUALVERIFY OP_CHECKSIG` | Base58Check(0x6F + hash160) | `m` or `n` |
| P2SH-P2WPKH | `OP_HASH160 <hash> OP_EQUAL` (wrapping witness) | Base58Check(0xC4 + hash160(witness_program)) | `2` |
| P2WPKH | witness v0 | Bech32(`bcrt`, 0, hash160) | `bcrt1q` |
| P2TR | witness v1 | Bech32m(`bcrt`, 1, tweaked_pubkey_x) | `bcrt1p` |

### Taproot specifics

- Use x-only public key (32 bytes, drop the prefix byte)
- Tweak: `tagged_hash("TapTweak", pubkey_x)` → `tweaked = pubkey + tweak * G`
- If tweaked Y is odd, negate the key
- Encode with Bech32m (witness version 1)
