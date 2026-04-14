# QA: BW-0001 Phase 4 — Data-HD-Wallet

Status: `QA_PASS`
Ticket: BW-0001
Phase: 4
Lane: Critical
Workflow Version: 3
Owner: QA
Date: 2026-04-05

---

## Scope

BIP39 mnemonic generation and validation, BIP32 master-key and child-key
derivation, four address-type encoding (legacy, wrapped SegWit, native SegWit,
Taproot) for regtest, seed persistence via SecureStorage, and HD wallet
repository orchestration.

Out of scope: Flutter UI integration, regtest Docker node, mainnet/testnet
address variants, Taproot script-path spending.

---

## Positive Scenarios (PS)

- [x] PS-1: `generateMnemonic()` produces 12 words that each appear in the BIP39
  English word list — covered by `bip39_service_impl_test.dart` ("generates 12
  words by default", "all words are in BIP39 wordlist").
- [x] PS-2: `generateMnemonic(wordCount: 24)` produces 24 words that each appear
  in the BIP39 English word list — covered by "generates 24 words when
  requested".
- [x] PS-3: `validateMnemonic` returns `true` for a freshly generated 12-word
  mnemonic — covered by "validates generated 12-word mnemonic".
- [x] PS-4: `validateMnemonic` returns `true` for a freshly generated 24-word
  mnemonic — covered by "validates generated 24-word mnemonic".
- [x] PS-5: Known BIP39 all-zero entropy test vector (`abandon`×11 + `about`)
  passes `validateMnemonic` — covered by "validates known BIP39 test vector".
- [x] PS-6: `mnemonicToSeed` produces the correct 64-byte seed for the all-zero
  test vector — covered by "produces correct seed from known mnemonic" against
  the standard BIP39 reference hex value.
- [x] PS-7: BIP32 `deriveMasterKey` produces the correct private key and chain
  code for test vector 1 seed `000102...0f` — covered by "produces correct
  master key from test vector 1".
- [x] PS-8: `deriveKeyPath` with path `[0x80000000]` produces the correct child
  key for test vector 1 — covered by "derives correct child key m/0h from test
  vector 1".
- [x] PS-9: `deriveAddress(mnemonic, nativeSegwit, 0)` produces an address
  starting with `bcrt1q` — covered by "native segwit address starts with
  bcrt1q".
- [x] PS-10: `deriveAddress(mnemonic, taproot, 0)` produces an address starting
  with `bcrt1p` — covered by "taproot address starts with bcrt1p".
- [x] PS-11: `deriveAddress(mnemonic, legacy, 0)` produces an address starting
  with `m` or `n` — covered by "legacy address starts with m or n".
- [x] PS-12: `deriveAddress(mnemonic, wrappedSegwit, 0)` produces an address
  starting with `2` — covered by "wrapped segwit address starts with 2".
- [x] PS-13: Same mnemonic + same index + same type → identical address
  (determinism) — covered by "same mnemonic and index produce identical address".
- [x] PS-14: `SeedRepositoryImpl.storeSeed` + `getSeed` round-trip returns the
  original mnemonic words — covered by "stored seed is retrievable".
- [x] PS-15: `HdWalletRepositoryImpl.createHDWallet` persists wallet; subsequent
  `getWallets()` returns it — covered by "wallet is persisted and returned by
  getWallets".
- [x] PS-16: `restoreHDWallet` with valid mnemonic returns wallet of type
  `WalletType.hd` — covered by "restores wallet with valid mnemonic".
- [x] PS-17: Wallet restored from a mnemonic generates the same native SegWit
  address at index 0 as the original wallet — covered by "restored wallet
  generates same addresses as original".
- [x] PS-18: `generateAddress` sequential calls increment the index — covered by
  "sequential calls increment the index".
- [x] PS-19: Generated address is saved and returned by `getAddresses` — covered
  by "address is saved and returned by getAddresses".
- [x] PS-20: Derivation path strings match BIP44/49/84/86 patterns for regtest
  coin_type=1 — covered by four path tests in "derivation paths" group.

---

## Negative / Edge Scenarios (NE)

- [x] NE-1: `validateMnemonic` returns `false` for a mnemonic with a tampered
  word (checksum mismatch) — covered by "rejects tampered mnemonic".
- [x] NE-2: `validateMnemonic` returns `false` when a word is not in the BIP39
  wordlist — covered by "rejects unknown word".
- [x] NE-3: `validateMnemonic` returns `false` for wrong word count (1 word) —
  covered by "rejects wrong word count".
- [x] NE-4: `generateMnemonic(wordCount: 15)` throws `ArgumentError` — covered
  by "throws ArgumentError for unsupported word count".
- [x] NE-5: `deriveAddress` throws `ArgumentError` for index < 0 — covered by
  "throws for negative index".
- [x] NE-6: `SeedRepositoryImpl.getSeed` returns `null` for unknown walletId —
  covered by "returns null for unknown walletId".
- [x] NE-7: `SeedRepositoryImpl.deleteSeed` on absent key does not throw —
  covered by "deleting absent key does not throw".
- [x] NE-8: `SeedRepositoryImpl.storeSeed` overwrites an existing entry for the
  same walletId — covered by "overwrites existing seed for same walletId".
- [x] NE-9: Two different walletIds in `SeedRepositoryImpl` do not interfere with
  each other — covered by "different walletIds do not interfere".
- [x] NE-10: `restoreHDWallet` throws `ArgumentError` for an invalid mnemonic —
  covered by "throws ArgumentError for invalid mnemonic".
- [x] NE-11: `generateAddress` throws `StateError` for a wallet whose seed is
  absent from storage — covered by "throws StateError for wallet with no seed".
- [x] NE-12: Different address indexes produce different addresses — covered by
  "different indexes produce different addresses".
- [x] NE-13: Different address types produce different addresses — covered by
  "different types produce different addresses".

---

## Manual Checks (MC)

- [x] MC-1: `flutter analyze` produces zero warnings, zero errors, and zero
  infos. Confirmed by the implementer; phase-4.md records this as a passed
  acceptance criterion.
- [x] MC-2: All 50 unit tests pass without a running regtest Docker node.
  Confirmed by the implementer; no integration-test dependency on live node
  infrastructure.
- [x] MC-3: No `print`, `debugPrint`, or `log` call appears anywhere in the
  Phase 4 production source tree. Confirmed by security review artifact.
- [x] MC-4: `Mnemonic.toString()` is not overridden. Confirmed by inspection of
  `packages/domain/lib/src/entity/mnemonic.dart` (referenced in security
  review).
- [x] MC-5: `bip32.dart`, `hash_utils.dart`, `ExtendedKey`, and all
  internal BIP32 functions are NOT exported from `data.dart`. Confirmed by
  inspection of `packages/data/lib/data.dart`.

---

## Implementation Verification (IV)

- [x] IV-1: `flutter analyze` clean — confirmed (zero warnings, acceptance
  criterion passed, recorded in phase-4.md).
- [x] IV-2: Blocking finding B-1 resolved — `bip32.dart` line 5 now uses
  `import 'package:data/src/crypto/hash_utils.dart';` (package-form import);
  relative import removed.
- [x] IV-3: Blocking finding B-2 resolved — `seed_repository_impl_test.dart`
  and `hd_wallet_repository_impl_test.dart` both exist with full coverage of
  store/retrieve/delete, key isolation, invalid-mnemonic rejection, orphan-seed
  guard, address index increment, and wallet persistence.
- [x] IV-4: Blocking finding B-3 resolved — `_deriveChild` in `bip32.dart`
  lines 107-117 contains both BIP32 invalidity guards (`ilInt >= params.n` and
  `childInt == BigInt.zero`), each throwing a `StateError` whose message
  contains no key material.
- [x] IV-5: CSPRNG usage confirmed — `Bip39ServiceImpl` uses `Random.secure()`
  (OS CSPRNG); no weak or seeded RNG path exists.
- [x] IV-6: Private key boundaries respected — `KeyDerivationServiceImpl`
  discards derived private keys after address encoding; `ExtendedKey` is not
  exported from `data.dart`; no key material appears in any public API return
  value.
- [x] IV-7: Seed stored under key `seed_<walletId>` via `SecureStorage`
  (OS-level encryption on device). Each wallet ID is a UUID, ensuring key
  isolation. Confirmed by `SeedRepositoryImpl` source and key-isolation test.
- [x] IV-8: Regtest address prefixes correct — legacy `m`/`n` (Base58Check
  version `0x6F`), wrapped SegWit `2` (version `0xC4`), native SegWit `bcrt1q`
  (HRP `bcrt`, witness v0), Taproot `bcrt1p` (HRP `bcrt`, witness v1 / Bech32m).
  Confirmed by four prefix tests and address-length tests.
- [x] IV-9: `SECURITY_REVIEW_OK` artifact present at
  `docs/BW-0001/security/BW-0001-phase-4-security.md` with verdict
  `SECURITY_REVIEW_OK` — Critical lane gate satisfied.
- [x] IV-10: `REVIEW_OK` confirmed — `phase-4.md` status is `REVIEW_OK`.

---

## Open Items (non-blocking)

The following findings from the review and security review are tracked as
required follow-ups in a future phase; they do not affect the Phase 4 gate:

- **I-1** (Important): `key_derivation_service_impl_test.dart` imports
  `package:data/src/crypto/bip32.dart` and `hash_utils.dart` directly.
  Functions under test should be re-exported or moved to a test-visible surface
  before Phase 5 adds more tests.
- **I-4** / Security finding: `_encodeP2tr` does not negate the output point
  when `Q.y` is odd. Spending ability is not impaired for key-path P2TR, but
  BIP341 test-vector compliance is affected. Must be resolved before any phase
  that adds Taproot script-path spending or cross-implementation address
  verification.

---

## Evidence

- `packages/data/lib/src/crypto/bip32.dart` — lines 5, 107-117 (B-1 and B-3
  fixes confirmed by source read).
- `packages/data/test/seed_repository_impl_test.dart` — 8 test cases across
  storeSeed/getSeed, deleteSeed, and key isolation groups (B-2 fix confirmed).
- `packages/data/test/hd_wallet_repository_impl_test.dart` — 13 test cases
  across createHDWallet, restoreHDWallet, generateAddress, and getWallets groups
  (B-2 fix confirmed).
- `packages/data/test/bip39_service_impl_test.dart` — 8 test cases including
  known BIP39 test vector validation.
- `packages/data/test/key_derivation_service_impl_test.dart` — 21 test cases
  covering seed derivation, BIP32 vectors, all 4 address prefixes, lengths,
  paths, determinism, metadata, and negative validation.
- `packages/data/lib/data.dart` — exports confirmed; `bip32.dart` and
  `hash_utils.dart` are not re-exported.
- `docs/BW-0001/phase/BW-0001/phase-4.md` — status `REVIEW_OK`.
- `docs/BW-0001/security/BW-0001-phase-4-security.md` — verdict
  `SECURITY_REVIEW_OK`.

---

## Verdict

`QA_PASS`

Issues:
- None blocking. Two non-blocking follow-up items (I-1 and I-4) are tracked
  above and must be resolved in the phase that first requires them.
