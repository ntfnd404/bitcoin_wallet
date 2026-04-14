# Review Summary: BW-0001 Phase 4 — Data-HD-Wallet

Status: `BLOCKING`
Ticket: BW-0001
Phase: 4
Lane: Critical
Workflow Version: 3
Owner: Reviewer
Date: 2026-04-05

---

## Verdict

`BLOCKING`

Three issues must be resolved before this phase can gate to security review:
relative imports in production crypto code, missing unit tests for the two new
repository impls, and a silent child-key invalidity path in the BIP32 derivation.

---

## Blocking Findings

### B-1 — Relative import in production source (`bip32.dart`)

`packages/data/lib/src/crypto/bip32.dart` line 7:

```dart
import 'hash_utils.dart';
```

The conventions document and code-style guide both state "Never use relative
imports — always `package:` imports". This file is production crypto code, not
a test helper, so the rule applies without exception. The correct import is:

```dart
import 'package:data/src/crypto/hash_utils.dart';
```

The project's `implementation_imports` linter rule is enabled, which will flag
`package:data/src/...` imports from outside the package but does NOT suppress
the requirement to use `package:` form inside the package itself. All other
files in the same package already use `package:` imports correctly; this one
stands out.

### B-2 — No unit tests for `SeedRepositoryImpl` or `HdWalletRepositoryImpl`

Phase 4 introduces two new repository implementations. The conventions document
requires unit tests for all Bitcoin-specific code, and the phase acceptance
criteria include "Unit tests pass without regtest node." Neither
`SeedRepositoryImpl` nor `HdWalletRepositoryImpl` has a corresponding test
file:

```
packages/data/test/bip39_service_impl_test.dart        -- exists
packages/data/test/key_derivation_service_impl_test.dart -- exists
packages/data/test/seed_repository_impl_test.dart      -- MISSING
packages/data/test/hd_wallet_repository_impl_test.dart -- MISSING
```

Required minimal coverage:
- `SeedRepositoryImpl`: store/retrieve round-trip, retrieve absent key returns
  null, delete removes key.
- `HdWalletRepositoryImpl`: create wallet stores seed and wallet metadata,
  restore wallet validates mnemonic and throws on invalid, generate address
  uses next index and delegates to key derivation, get addresses delegates to
  local store.

These are all testable with an in-memory `SecureStorage` fake; no regtest node
is needed.

### B-3 — BIP32 child-key invalidity not handled (silent data corruption)

`_deriveChild` in `bip32.dart` does not check `ilInt >= params.n` (the BIP32
spec requires that when `IL >= n` the key at this index is invalid and the
wallet must skip to `index + 1`). Currently:

```dart
final childInt = (parentInt + ilInt) % params.n;
```

If `ilInt >= params.n`, the modular arithmetic silently produces a key that
does not correspond to a valid BIP32 node. Per BIP32 specification this case
"should be handled by skipping to the next index." The probability is
negligible (~1 in 2^127) but for a Critical-lane crypto primitive the
unhappy-path must be either handled or explicitly documented as a known
acceptable risk. Since the same check is already present in `_encodeP2tr`
for the taproot tweak, the pattern is established in the codebase.

Minimum required action: throw `StateError` (consistent with the rest of the
file) with a message that does NOT include any key material, and document the
case in the method comment.

---

## Important Findings

### I-1 — Test uses internal `package:data/src/...` imports

`key_derivation_service_impl_test.dart` lines 2–3:

```dart
import 'package:data/src/crypto/bip32.dart';
import 'package:data/src/crypto/hash_utils.dart';
```

The `implementation_imports` linter rule flags imports of `src/` paths from
outside the declaring package. Tests live in `packages/data/test/` which is
outside `lib/`, so these are cross-package-boundary `src/` imports. The
functions under test (`mnemonicToSeed`, `deriveMasterKey`, `deriveKeyPath`,
`privateKeyToPublic`, `bytesToHex`, `hexToBytes`) should either be re-exported
from `data.dart` or the test should be co-located inside the package's own
`lib/` via a test-only export. This is not blocking today only because the
linter rule targets inter-package usage, but it is a maintenance risk and
should be resolved before Phase 5 adds more tests.

### I-2 — `HdWalletRepositoryImpl` member ordering deviates from DCM config

The DCM `member-ordering` rule requires `constructors` before
`private-static-const-fields`. In `HdWalletRepositoryImpl` the static field
`_uuid` appears after the constructor, which matches the style guide correctly.
However the instance fields `_bip39`, `_keyDerivation`, `_seedRepository`, and
`_localStore` are declared after `_uuid`. According to the DCM ordering config,
`private-static-const-fields` must precede `final-private-fields`. This is
already correct in the file. No action required — flagged for awareness only.

### I-3 — `SeedRepositoryImpl.getSeed` does not validate word count after
split

When reading back from storage, `raw.split(' ')` will produce a list of any
length if the stored value was corrupted. The resulting `Mnemonic` will fail
`validateMnemonic` at call sites but `getSeed` itself returns it without
indication. This is acceptable given the current interface contract (`getSeed`
is not required to validate), but it warrants a doc comment noting the
assumption.

### I-4 — `_encodeP2tr` uses `lift_x` with forced even-Y assumption

The implementation decodes the x-only key using prefix `0x02` (even Y) which
is the correct BIP341 `lift_x` semantic. However, it does not subsequently
check whether the output point `Q`'s Y coordinate is odd and negate the key as
required when `Q.y` is odd. The plan specification states: "If tweaked Y is
odd, negate the key." The current code derives the output x-coordinate without
negation. For key-path-only P2TR this affects address correctness for ~50% of
keys. This is a potential correctness defect; the address prefix tests pass
because Bech32m encoding only uses the x-coordinate, but the output key
commitment will be wrong when `Q.y` is odd. Needs verification against a BIP341
test vector with a known odd-Y output key.

---

## Deviations From Plan

- Plan and PRD documents are both `STUB` (filled with template placeholder
  text only). All review was conducted against `phase-4.md` which contains
  the substantive acceptance criteria and technical details. This is a process
  deviation; the plan and PRD should have been filled before implementation.

- `KeyDerivationService` interface doc comment references
  `BitcoinNetwork`-dependent `coinType`, but `KeyDerivationServiceImpl`
  hardcodes `_coinType = 1` (regtest). This matches the current phase scope
  (regtest only) but diverges from the interface contract. The deviation is
  acceptable for Phase 4 and should be tracked for the network-switching phase.

---

## Regression Checks

- `NodeWalletRepositoryImpl` and `WalletLocalStore` (Phase 3) — not modified;
  no regression risk from this phase.
- `data.dart` exports — both new impls are correctly exported; no existing
  exports were removed.
- Domain interfaces — none modified; all three `SeedRepositoryImpl`,
  `HdWalletRepositoryImpl`, and `KeyDerivationServiceImpl` fully satisfy their
  respective interface contracts.
- BIP39 service — unchanged from previous implementation; existing tests
  remain valid.

---

## Security Notes (Critical Lane)

- Mnemonic is stored as a space-joined string under `seed_<walletId>` in
  `SecureStorage`. The key format is predictable but the underlying
  `flutter_secure_storage` provides OS-level encryption. Acceptable.
- `Mnemonic.toString()` is not overridden (by design per domain entity comment),
  preventing accidental log exposure. No key material appears in any `StateError`
  or `ArgumentError` messages reviewed. Conventions respected.
- `Bip39ServiceImpl` uses `Random.secure()` (OS CSPRNG). No weak RNG path
  exists.
- No private key material is returned by any public API. `KeyDerivationServiceImpl`
  discards the derived private key after address encoding. Conventions respected.

---

## Next Action

1. Fix relative import in `bip32.dart` (B-1).
2. Add `seed_repository_impl_test.dart` and `hd_wallet_repository_impl_test.dart` (B-2).
3. Add `ilInt >= params.n` guard in `_deriveChild` (B-3).
4. Verify P2TR output-key negation against a BIP341 odd-Y test vector (I-4).
5. After fixes, re-run `flutter analyze --fatal-infos --fatal-warnings` and
   confirm zero findings.
6. Update phase-4.md status to `REVIEW_OK` once all blocking items are resolved.
