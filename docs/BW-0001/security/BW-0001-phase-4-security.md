# Security Review: BW-0001 Phase 4 — Data-HD-Wallet

Status: `SECURITY_REVIEW_OK`
Ticket: BW-0001
Phase: 4
Lane: Critical
Workflow Version: 3
Owner: Security Reviewer
Date: 2026-04-05

---

## Scope

BIP39 mnemonic generation and validation, BIP32 master-key and child-key
derivation, Taproot output-key tweaking, seed persistence in SecureStorage,
HD wallet repository orchestration.  All paths where secret material
(entropy, mnemonic words, private keys, PBKDF2 output) enters, moves through,
or leaves the system were traced.

Artifacts reviewed:
- `packages/data/lib/src/crypto/bip32.dart`
- `packages/data/lib/src/crypto/hash_utils.dart`
- `packages/data/lib/src/service/bip39_service_impl.dart`
- `packages/data/lib/src/service/key_derivation_service_impl.dart`
- `packages/data/lib/src/repository/seed_repository_impl.dart`
- `packages/data/lib/src/repository/hd_wallet_repository_impl.dart`
- `packages/data/lib/data.dart` (export surface)
- `packages/domain/lib/src/entity/mnemonic.dart`
- `packages/storage/lib/src/secure_storage.dart`
- `packages/storage/lib/src/secure_storage_impl.dart`
- `packages/data/test/seed_repository_impl_test.dart`
- `packages/data/test/hd_wallet_repository_impl_test.dart`

---

## Checks

- [x] Secrets and sensitive data never logged
- [x] Private material stays in the correct layer
- [x] Error handling does not leak security state
- [x] Storage / network / auth changes match the plan
- [x] No unsafe fallback or downgrade path was introduced

---

## Findings

### Entropy source

`Bip39ServiceImpl._generateEntropy` calls `Random.secure()` from `dart:math`,
which delegates to the platform OS CSPRNG.  No weak or seeded RNG path exists.
128 bits of entropy for 12-word and 256 bits for 24-word mnemonics match BIP39
exactly.

### Mnemonic in memory and error messages

`Mnemonic` does not override `toString()`; the default Dart implementation
returns `"Instance of 'Mnemonic'"`.  This is enforced by a doc comment on the
class.

`HdWalletRepositoryImpl.restoreHDWallet` throws
`ArgumentError.value(mnemonic, 'mnemonic', 'BIP39 validation failed')`.
Dart formats this as:
`"Invalid argument(s) (mnemonic): BIP39 validation failed (Instance of 'Mnemonic')"`.
Because `Mnemonic.toString()` does not expand word material, no seed words
appear in the exception message or any stack trace that would be logged.

No `print`, `debugPrint`, or `log` calls are present anywhere in the reviewed
source tree.

### Seed storage

`SeedRepositoryImpl.storeSeed` writes the space-joined mnemonic string under
the key `seed_<walletId>` via `SecureStorage.setString`.
`SecureStorageImpl` delegates to `flutter_secure_storage`, which uses
OS-level encryption (Keychain on iOS, Keystore/EncryptedSharedPreferences on
Android).  The value never touches unencrypted disk or network.

Key scoping is correct: each wallet gets an isolated storage key derived from
its UUID.  A test in `seed_repository_impl_test.dart` (`key isolation` group)
confirms that two different wallet IDs do not interfere.

### Private key boundaries

`KeyDerivationServiceImpl.deriveAddress` is the only public entry-point that
touches private key material.  The call sequence is:

  mnemonic.words → mnemonicToSeed (PBKDF2) → deriveMasterKey → deriveKeyPath
  → privateKeyToPublic → address encoding → Address (value only)

`ExtendedKey` (private key + chain code) is used only inside
`packages/data/lib/src/crypto/bip32.dart` and is not exported from
`data.dart`.  The domain `Address` entity returned to callers contains only
the encoded address string, type, wallet ID, index, and derivation path — no
key material.

### BIP32 child-key invalidity guards

`_deriveChild` now contains both required guards:
1. `if (ilInt >= params.n)` — throws `StateError` with a message that contains
   no key material.
2. `if (childInt == BigInt.zero)` — same.

Both messages are safe for logging: they do not include the IL value, parent
private key, or chain code.  This resolves the previously blocking finding B-3.

### Taproot output-key negation (P2TR odd-Y)

`_encodeP2tr` does not negate the output point when `Q.y` is odd.  The BIP341
specification requires that when the output key `Q`'s Y coordinate is odd the
implementation negate `Q` before encoding the x-coordinate.  The current code
encodes `Q.x` unconditionally.

For key-path-only P2TR, Bech32m encoding uses only the x-coordinate, so the
produced address string is identical regardless of Y parity.  However the
output public key commitment embedded in the scriptPubKey will be `lift_x(Q.x)`
which is always the even-Y variant.  If the actual `Q.y` is odd this means the
effective spending key is the negation of `Q`, which is still a valid key the
wallet controls (since negation of `Q = P + tG` is still derivable from the
same private key).  Spending ability is therefore not impaired.

This is a correctness issue that affects BIP341 test-vector compliance and
future compatibility with Taproot script-path spending (not in scope for Phase
4), not a secret-material leakage issue.  It does not expose private key
material, enable key recovery, or allow theft.

It was already classified as finding I-4 (Important, not Blocking) by the code
reviewer.  From a security standpoint it introduces no new trust-boundary
violation or key-material exposure and does not warrant blocking this review.
It must be resolved before any phase that introduces Taproot script-path
spending.

### Public API surface

`data.dart` exports:
- `Bip39ServiceImpl`, `KeyDerivationServiceImpl` — implementation types, no
  key fields exposed.
- `SeedRepositoryImpl`, `HdWalletRepositoryImpl` — constructor parameters are
  domain interfaces; no key fields on the instances.
- `WalletLocalStore` — wallet and address metadata only.
- `bip39_wordlist.dart` — the BIP39 English word list.  This is public
  reference data, not sensitive.

`bip32.dart`, `hash_utils.dart`, `ExtendedKey`, `mnemonicToSeed`,
`deriveMasterKey`, `deriveKeyPath`, `privateKeyToPublic` are NOT exported from
`data.dart`.  They are reachable from tests via `src/` import paths
(reviewer finding I-1), but that is a test-maintenance concern, not a runtime
trust-boundary violation.

### No network or auth changes

Phase 4 introduces no network calls, no authentication flows, and no
migration of existing storage entries.  No downgrade path exists.

---

## Required Follow-ups

1. Fix Taproot output-key negation (I-4 from code review) before any phase that
   adds Taproot script-path spending or cross-implementation address
   verification.  Track as a separate task in the relevant phase.
2. Eliminate `src/` import paths from `key_derivation_service_impl_test.dart`
   (code-review finding I-1) to close the implementation-boundary gap.

---

## Verdict

`SECURITY_REVIEW_OK`
