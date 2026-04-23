# Security Review: BW-0003 Phase 1 — Key Derivation and Self-Signing

Status: `SECURITY_REVIEW_OK`
Ticket: BW-0003
Phase: 1
Lane: Critical
Workflow Version: 3
Owner: security-reviewer
Date: 2026-04-23

---

## Scope

- ECDSA signing with deterministic k derivation (`packages/keys/lib/src/data/crypto/ecdsa.dart`)
- BIP32 HD key derivation from mnemonic/seed (`packages/keys/lib/src/data/crypto/bip32.dart`)
- Seed storage and retrieval (`packages/keys/lib/src/data/seed_repository_impl.dart`)
- Transaction signing use case and private key lifetime (`packages/keys/lib/src/application/sign_transaction_use_case.dart`)
- Signing service — key material flow through signing pipeline (`packages/keys/lib/src/data/transaction_signing_service_impl.dart`)
- Bech32/Bech32m address encoding and decoding (`packages/keys/lib/src/data/crypto/bech32.dart`)
- ManualUtxoScope DI — trust boundary between AppScope and UI layer (`lib/feature/signing/manual_utxo/di/manual_utxo_scope.dart`)
- HdTransactionSigner adapter — bridge between transaction domain and keys package (`lib/core/adapters/hd_transaction_signer.dart`)
- XpubBloc and xpub display surface (`lib/feature/signing/xpub/`)
- SigningDemoScreen — UI surface that touches signing flow (`lib/feature/signing/manual_utxo/view/screen/signing_demo_screen.dart`)

---

## Checks

- [x] Secrets and sensitive data never logged
- [x] Private material stays in the correct layer
- [x] Error handling does not leak security state
- [x] Storage / network / auth changes match the plan
- [x] No unsafe fallback or downgrade path was introduced

---

## Findings

### Finding 1 — k derivation: Fortuna PRNG, not RFC 6979 HMAC-DRBG (Known Limitation)

**File:** `packages/keys/lib/src/data/crypto/ecdsa.dart`

k is seeded from `sha256(privateKey ‖ sighash)` fed into PointyCastle's Fortuna PRNG. This achieves determinism — the same `(privateKey, sighash)` pair always produces the same k — which prevents k-reuse across calls. Low-S normalization (BIP62) is correctly applied.

The deviation from RFC 6979 is that Fortuna is a stream cipher based PRNG, not an HMAC-DRBG. The security argument is: the seed is a cryptographic hash of both the private key and the message hash, making it unique and unpredictable to any party who does not know the private key. k-reuse cannot occur for distinct `(privateKey, sighash)` pairs.

**Risk:** Non-standard k derivation that has not been subject to the same formal analysis as RFC 6979. The Fortuna internal state after seeding with 32 bytes and drawing one k value has not been independently audited in this configuration.

**Scope determination:** Regtest-only portfolio project. No mainnet exposure. Acceptable.

---

### Finding 2 — Private key not zeroed after signing (Known Limitation)

**File:** `packages/keys/lib/src/application/sign_transaction_use_case.dart`, `packages/keys/lib/src/domain/entity/signing_input.dart`

`SigningInput.privateKey` is a `Uint8List` held in memory for the duration of `signP2wpkh`. It is not explicitly zeroed after signing. The `SigningInput` doc comment acknowledges this: "must be zeroed after signing (caller's responsibility)" — but the caller (`TransactionSigningServiceImpl`) does not do so.

Dart does not expose a guaranteed secure memory wipe primitive. The GC may retain the backing buffer in memory for an indeterminate period. In a sandboxed mobile/desktop app without a memory inspection attack surface, this is a low practical risk.

**Risk:** Key material may linger in process heap until GC collects it. No crash dump or memory inspection vector has been identified in the current regtest configuration.

**Scope determination:** Regtest-only portfolio project. No mainnet exposure. Acceptable.

---

### Finding 3 — Seed retrieval re-derives full key path for every input (Observation, not a blocker)

**File:** `packages/keys/lib/src/application/sign_transaction_use_case.dart` lines 37-55

For each UTXO input, `derivePrivateKey` and `derivePublicKey` are called separately. Each call independently runs `mnemonicToSeed` (PBKDF2-HMAC-SHA512, 2048 iterations) and the full BIP32 path derivation. The mnemonic is fetched once per `call()` invocation, which is correct. The extra PBKDF2 rounds per input increase CPU time but do not introduce a security weakness — the seed bytes are never cached outside the call stack, which limits their in-memory lifetime.

**Risk:** None from a security perspective. Performance concern only.

---

### Finding 4 — Address validation at the signing boundary is HRP-scoped only

**File:** `packages/keys/lib/src/data/crypto/tx_builder.dart` — `p2wpkhScriptFromAddress`

Recipient addresses are validated by `segwitDecode`, which checks HRP match and bech32 checksum, then enforces a 20-byte witness program (P2WPKH). A non-P2WPKH witness program (e.g., P2WSH with 32-byte program) will return null and cause `ArgumentError` before signing. Taproot addresses are implicitly rejected. This is the correct conservative behavior for a P2WPKH-only signing implementation.

**Risk:** None. Reject-on-mismatch is the safe path.

---

### Finding 5 — xpub display does not expose private key material to the UI

**File:** `lib/feature/signing/xpub/view/screen/xpub_screen.dart`, `packages/keys/lib/src/application/get_xpub_use_case.dart`

`GetXpubUseCase` returns only the serialized account xpub (Base58Check-encoded public key + chain code). The mnemonic is fetched from `SeedRepository` inside the use case and never propagated to the caller. The `AccountXpub` domain object contains only `xpub: String` and `derivationPath: String` — no private material.

The xpub is displayed via `CopyableText`. This is an intentional UX feature (user copies xpub to verify with external tools). No concern.

**Risk:** None. Trust boundary is maintained. Private key never crosses into the BLoC or UI layer.

---

### Finding 6 — ManualUtxoScope does not leak private key material to UI

**File:** `lib/feature/signing/manual_utxo/di/manual_utxo_scope.dart`, `lib/feature/signing/manual_utxo/bloc/signing_bloc.dart`

`SigningBloc` receives `SignTransactionUseCase` — not a mnemonic, not a private key. The signing flow is: UI emits `SignAndBroadcastRequested` containing `walletId`, `recipientAddress`, `amountSat`, `bech32Hrp`. No key material enters the event. The BLoC assembles `SigningInputParam` objects (containing only txid, vout, amountSat, address type, derivation index) and passes them to the use case. The use case resolves the private key internally via `SeedRepository`. The raw transaction hex returned is the only output; it is passed directly to `broadcastTransaction` and the resulting txid is emitted to state for display.

**Risk:** None. The trust boundary between the UI/BLoC layer and the keys package is correct. No private material is present in `SigningState` or any BLoC event.

---

### Finding 7 — Error messages in signing path do not expose key material

**File:** `lib/feature/signing/manual_utxo/bloc/signing_bloc.dart`

Caught exceptions are surfaced as `e.toString()` in `SigningState.errorMessage`. The exception types thrown by the keys package are `StateError` and `ArgumentError` with messages such as "No seed found for wallet X", "Cannot decode address: Y", "Derived IL >= curve order". None of these messages contain key bytes, mnemonic words, or chain codes.

**Risk:** None identified. The `walletId` is a non-sensitive identifier.

---

### Finding 8 — Seed storage uses SecureStorage with predictable key format

**File:** `packages/keys/lib/src/data/seed_repository_impl.dart`

Seed is stored under the key `seed_<walletId>`. WalletId is an app-internal identifier (not user-visible input). `SecureStorage` is backed by the platform keychain (iOS Keychain / Android Keystore on mobile, macOS Keychain on desktop). The key naming scheme is simple and deterministic, which is appropriate.

The mnemonic is stored as a space-joined string of 12 or 24 words. No encryption layer beyond what `SecureStorage` provides is applied. This is standard practice for Flutter wallets targeting regtest.

**Risk:** None beyond the trust model of the underlying platform secure storage, which is out of scope.

---

### Finding 9 — BIP32 child key derivation handles invalid key cases correctly

**File:** `packages/keys/lib/src/data/crypto/bip32.dart`

`_deriveChild` correctly checks `ilInt >= params.n` (IL exceeds curve order) and `childInt == BigInt.zero` (degenerate key), throwing `StateError` in both cases as specified by BIP32. The `EC point at infinity` check in `privateKeyToPublic` is also present. These guard conditions are necessary for a correct BIP32 implementation.

**Risk:** None. Guards are in place.

---

### Finding 10 — Change output is conditionally suppressed when changeSat is zero

**File:** `lib/core/adapters/hd_transaction_signer.dart` lines 40-42

```dart
if (changeSat.value > 0) SigningOutput(address: changeAddress, amountSat: changeSat),
```

When `changeSat` is zero, no change output is created. This is correct behavior for the demo scope — it avoids dust outputs. In a production wallet this would need a fee calculation layer to ensure change is properly handled, but for regtest demo this is acceptable.

**Risk:** None for regtest scope.

---

## Required Follow-ups

The following items must be addressed before any mainnet or production use. They are out of scope for this regtest-only portfolio phase.

1. **Replace Fortuna PRNG with full RFC 6979 HMAC-DRBG** for standard-compliant deterministic k derivation before any production use.
2. **Implement explicit zeroing of `SigningInput.privateKey`** after `signP2wpkh` returns. Until Dart exposes a secure memory wipe, consider using a `try/finally` block with a manual byte-fill (`fillRange(0, length, 0)`) as a best-effort mitigation.
3. **Add fee validation** to the signing path — the current implementation allows a caller to construct transactions where all UTXO value goes to outputs, potentially producing zero-fee transactions that will not relay on mainnet.

---

## Verdict

`SECURITY_REVIEW_OK`

All security-critical trust boundaries are correctly implemented. Private key material is confined within the `keys` package and never crosses into BLoC or UI layers. Seed storage delegates to platform SecureStorage. Error messages do not expose key material. The two known limitations (non-RFC-6979 k derivation, no post-signing key zeroing) are explicitly acknowledged and are acceptable within the declared regtest-only scope of this ticket.
