# ADR-001: Dissolve `address` Package into `wallet`

Status: Accepted
Date: 2026-05-15
Ticket: BW-0011
Authors: ntfnd404

---

## Context

The project originally had a standalone `packages/address/` package that owned:
- `Address` entity
- `AddressRepository` contract and implementation
- `AddressException` hierarchy
- `AddressGenerationStrategy` interface and two concrete strategies (`HdAddressGenerationStrategy`, `NodeAddressGenerationStrategy`)
- `GenerateAddressUseCase`

The `wallet` package depended on `address` for address generation. The `transaction` package depended on `address` for `Address` entities used in UTXO scan and HD send preparation.

### Problem

`address` had no independent aggregate root. An `Address` only exists in the context of a `Wallet` — it is derived from a wallet's mnemonic and always belongs to a specific wallet ID. Querying, generating, or storing addresses always requires wallet context.

Two symptoms confirmed the wrong boundary:
1. `AddressGenerationStrategy` received a `Wallet` as its first argument — the address package depended on the wallet package's entity in everything but name.
2. `AddressRepository.getAddresses(walletId)` — every repository call took a `walletId`, making `address` a sub-domain of `wallet`, not a peer.

### Options considered

**Option A — Keep `address` as a separate package.**
Pro: clear surface area, `address` stays small.
Con: artificial boundary. Consumers always import both `address` and `wallet`. The DIP relationship (wallet uses address) ran backwards in practice.

**Option B — Dissolve `address` into `wallet`.**
Pro: reflects domain reality (addresses are part of wallet aggregate). Removes a cross-package import cycle smell. Consumers import one package. Enables `wallet` to own the full address lifecycle.
Con: `wallet` barrel grows; must update all consumers.

**Option C — Dissolve `address` into `shared_kernel`.**
Rejected immediately: `Address` is a business entity, not a shared primitive. `shared_kernel` must remain zero-business-logic.

---

## Decision

**Option B — dissolve `address` into `wallet`.**

All symbols from `packages/address/` were moved to `packages/wallet/`:
- `Address`, `AddressType` (was already in `shared_kernel` — kept there)
- `AddressRepository`, `AddressRepositoryImpl`
- `AddressException`, `AddressGenerationException`, `AddressStorageException`, `AddressNoStrategyException`
- `AddressGenerationStrategy`, `HdAddressGenerationStrategy`, `NodeAddressGenerationStrategy`
- `GenerateAddressUseCase`

The `packages/address/` directory was deleted.

---

## Consequences

**Positive:**
- Single import point for wallet-domain consumers: `package:wallet/wallet.dart`
- `transaction` package, which needed `Address` for UTXO scan, now imports from `wallet` — reflecting the real ownership chain (transactions involve wallet addresses)
- Reduced workspace package count

**Negative / known limitations:**
- `wallet` barrel is larger; Phase 6 (barrel narrowing) will address this
- `transaction` depending on `wallet` for `Address` and `AddressRepository` is a coupling that must be managed — see ADR-002 for a related boundary question

**Impact on future work:**
- Phase 6 (BW-0012) must verify that `wallet.dart` barrel only exports public-contract symbols, not implementation types from the merged address domain
- Address-related fakes in tests now import from `package:wallet/wallet.dart`
