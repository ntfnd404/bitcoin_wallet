# Security Review Artifact: BW-0005 Phase 2

Status: SECURITY_REVIEW_PASS
Ticket: BW-0005
Phase: 2
Lane: Critical
Date: 2026-04-25
Reviewer: security-reviewer agent

---

## Scope

Removal of `HdAddressEntry` value object from `packages/transaction/`; declaration of
`transaction → address` path dependency; all `HdAddressEntry` reference sites replaced
with `Address` from `packages/address/`.

---

## Trust Boundary Analysis

### Before Phase 2
`transaction` held a local mirror (`HdAddressEntry`) of three fields from `Address`:
- `address` (String) → now `value`
- `index` (int)
- `type` (AddressType)

The mirror prevented `transaction` from seeing any `Address`-specific fields not explicitly
mirrored, including `derivationPath`.

### After Phase 2
`transaction` has an explicit `package:address` dependency and can import any field of `Address`.
The **accessible** surface of HD metadata inside `transaction` is widened; the **used** surface
is not widened — only `value`, `index`, and `type` are read.

---

## Security Invariants Verified

### 1. Key material boundary unchanged
- Private keys, WIFs, seed bytes remain inside `packages/keys/`.
- `Address` carries no key material (verified: `address.dart` holds `value`, `type`, `walletId`,
  `index`, `derivationPath` only — no key bytes).
- No modified file gains the ability to sign or access key material.
- **Result: PASS**

### 2. `derivationPath` not newly read
- `packages/transaction/lib/src/domain/entity/utxo.dart` lines 36 and 50: pre-existing field
  *declaration* on `Utxo`, not a new read site introduced by Phase 2.
- `PrepareHdSendUseCase` reads only `entry.index`, `entry.type`, `e.value` from `Address`.
- `HdAddressDataSourceImpl` passes `Address` objects through without reading any field.
- No hit exists in any modified file for `derivationPath`.
- **Result: PASS**

### 3. No new telemetry or logging surface
- No `developer.log`, `print`, error-message interpolation, or exception string in any modified
  file (`hd_address_data_source.dart`, `hd_address_data_source_impl.dart`,
  `prepare_hd_send_use_case.dart`, `transaction.dart` barrel) references `derivationPath`,
  `index`, or other HD metadata.
- **Result: PASS**

### 4. Signing call sites unchanged
- `PrepareHdSendUseCase` constructs `SigningInput` with `derivationIndex: entry.index` and
  `addressType: entry.type` — semantically identical to before Phase 2.
- `HdTransactionSigner` and `keys/SignTransactionUseCase` are not touched.
- **Result: PASS**

### 5. `HdAddressEntry` fully removed
- No export or reference to `HdAddressEntry` found in `packages/transaction/lib/transaction.dart`
  or anywhere in the barrel.
- **Result: PASS**

### 6. `packages/keys/` not touched
- No file inside `packages/keys/` appears in Phase 2 changes.
- **Result: PASS**

---

## `derivationPath` Exposure Invariant

After Phase 2: only `HdAddressGenerationStrategy` (inside `packages/address/`) writes
`derivationPath`. The two hits from grep are a pre-existing field declaration on `Utxo` —
not a read site on `Address`. No code outside `packages/address/` or `packages/keys/`
reads `Address.derivationPath`.

---

## Checklist

- [x] Key material boundary unchanged
- [x] `derivationPath` not newly read in `transaction` or adapters
- [x] No new logging/telemetry surface
- [x] Signing call sites unchanged
- [x] `HdAddressEntry` fully removed (zero references remaining)
- [x] `packages/keys/` not touched

---

## Findings Summary

All six checks pass. The widened import surface (`transaction` can now see `Address.derivationPath`)
is architecturally noted but presents no active risk: no code in `packages/transaction/` or
`lib/core/adapters/` reads that field. `SigningInput` construction is bit-for-bit equivalent to
the pre-Phase-2 path. No logging or telemetry surface was introduced. Key material remains
entirely within `packages/keys/`.

Reviewer date: 2026-04-25
