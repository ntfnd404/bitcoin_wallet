# ADR-002: `SigningInput` Ownership — `transaction` vs `shared_kernel`

Status: Accepted
Date: 2026-05-15
Ticket: BW-0012 Phase 1 / Phase 3
Authors: ntfnd404

---

## Context

Two distinct `SigningInput` types exist in the codebase:

| Type | Package | Fields |
|------|---------|--------|
| `tx.SigningInput` | `packages/transaction/lib/src/domain/value_object/signing_input.dart` | `txid`, `vout`, `amountSat`, `address`, `derivationIndex`, `addressType` |
| `keys.SigningInput` | `packages/keys/lib/src/domain/entity/signing_input.dart` | `txid`, `vout`, `amountSat`, `privateKey: Uint8List`, `publicKey: Uint8List` |

`keys.SigningInput` carries raw private-key material and is an internal type of the `keys` bounded context. It was removed from the `keys` public barrel in Phase 2 (BW-0012). It is not a candidate for `shared_kernel`.

The ownership question for **this ADR is about `tx.SigningInput` only**.

### The question

`tx.SigningInput` is produced by `PrepareHdSendUseCase` (in `transaction`) and consumed by `HdTransactionSigner` (app-layer adapter in `lib/core/adapters/`). It carries `derivationIndex` and `addressType` — fields that describe the HD derivation path for a specific UTXO. These are needed by the signing adapter to call `keys.SignTransactionUseCase` with the correct key derivation parameters.

The question: should `tx.SigningInput` remain in `packages/transaction/` or move to `packages/shared_kernel/`?

### Options considered

**Option A — Keep `tx.SigningInput` in `packages/transaction/`.**

`tx.SigningInput` is fundamentally a **spend descriptor** for a UTXO in an HD transaction. It says: "to spend this UTXO, use the key at derivation path `type/index` for the address that owns it." This is transaction-domain knowledge — it describes an input to a Bitcoin transaction, not a general-purpose shared primitive.

**Option B — Move `tx.SigningInput` to `packages/shared_kernel/`.**

Rationale: `HdTransactionSigner` needs it, and the adapter bridges `transaction` and `keys`. Putting it in `shared_kernel` would let both packages reference it without a dependency between them.

Counter-argument: `shared_kernel` must contain zero business logic and only tiny shared primitives (`Satoshi`, `AddressType`, `BitcoinNetwork`). `SigningInput` contains `derivationIndex` and `address` — UTXO-level domain information. Adding it to `shared_kernel` would begin the creep of business entities into the shared kernel, violating the foundational rule.

**Option C — Move `tx.SigningInput` to a new `signing_port` package.**

Rationale: create a neutral package that both `transaction` and the app adapter can depend on.
Rejected: introduces a new package for one type. The app-layer adapter (`HdTransactionSigner`) already resolves the dependency direction — it imports from `transaction` (for `tx.SigningInput`) and calls into `keys` (via the `SignTransaction` typedef). No neutral package is needed when the adapter already provides the bridging layer.

---

## Decision

**Option A — `tx.SigningInput` stays in `packages/transaction/`.**

Rationale:
1. `tx.SigningInput` describes a UTXO input to a Bitcoin transaction. It is a value object owned by the `transaction` bounded context.
2. `derivationIndex` and `addressType` are properties of the address that owns the UTXO — they are part of the spend descriptor, not of key management.
3. Moving it to `shared_kernel` would violate the shared_kernel zero-business-logic rule.
4. `HdTransactionSigner` already correctly bridges the boundary: it imports `tx.SigningInput` from `transaction` and calls `keys.SignTransactionUseCase` through the `SignTransaction` typedef. The adapter is the right place for this bridging.
5. No external consumer currently imports `tx.SigningInput` from outside `transaction` — it is already effectively internal despite being exported from the barrel. Phase 6 should consider removing it from the `transaction` public barrel.

---

## Consequences

**Phase 6 implication:**
`tx.SigningInput` should be removed from the `transaction.dart` public barrel in Phase 6. It is consumed only by `HdTransactionSigner` (app layer) which can use a `src/` import. Removing it from the barrel closes the path by which future external code could accidentally reference this spend-descriptor type.

**No dependency changes required.**
`transaction` already depends on `wallet` (for `AddressRepository` used in `PrepareHdSendUseCase`). No new deps are introduced by this decision.

**`keys.SigningInput` (the private-key-bearing type) is separately addressed:**
Phase 2 (BW-0012) removed `keys.SigningInput` from the `keys` public barrel. Its ownership is and remains internal to `keys`. It is not a candidate for `shared_kernel` under any circumstances.
