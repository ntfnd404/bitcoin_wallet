# Research: BW-0005 Phase 2 — Remove `HdAddressEntry`, Use `Address` Directly

Status: `RESEARCH_DONE`
Ticket: BW-0005
Phase: 2
Lane: Critical
Workflow Version: 3
Owner: Researcher

---

## Codebase Facts

### `HdAddressEntry` removal footprint

`grep -n "HdAddressEntry"` across `packages/`, `lib/`, `test/` returns
seven references in five distinct kinds:

| # | Absolute path | Line(s) | Kind |
|---|---|---|---|
| 1 | `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/domain/value_object/hd_address_entry.dart` | 6, 11 | declaration of `final class HdAddressEntry` and its const constructor — file to delete |
| 2 | `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/domain/data_sources/hd_address_data_source.dart` | 1 (`import`), 9 (return type `Future<List<HdAddressEntry>>`) | import + type annotation on `getAddressesForWallet` |
| 3 | `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/transaction.dart` | line `export 'src/domain/value_object/hd_address_entry.dart';` | barrel re-export to remove |
| 4 | `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/lib/core/adapters/hd_address_data_source_impl.dart` | 15 (return type), 20 (instantiation `HdAddressEntry(address: a.value, index: a.index, type: a.type)`) | implementation that maps `Address → HdAddressEntry` |
| 5 | `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/prepare_hd_send_use_case.dart` | 39 (`getAddressesForWallet`), 41 (`.where((e) => e.type == ...)`), 44 (`e.address`), 60 (`addressLookup[e.address] = e`), 75–80 (reads `entry.index`, `entry.type` to build `SigningInput`), 90 (sort by `e.index`) | indirect: consumes the type's three fields (`address`, `index`, `type`) |

No tests reference `HdAddressEntry` (`grep` in `test/` returns no matches).

Total reference sites: **5 source files** (one declaration, two type
annotations on the data-source contract + barrel, one impl with
field-by-field copy, one consumer use case that reads three fields).

### Field comparison: `HdAddressEntry` vs `Address`

`HdAddressEntry` (from
`/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/domain/value_object/hd_address_entry.dart`):

```
String address          // string value of the address
int    index            // derivation index
AddressType type        // legacy / wrappedSegwit / nativeSegwit / taproot
```

`Address` (from
`/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/src/domain/entity/address.dart`):

```
String value            // ← matches HdAddressEntry.address (different name!)
AddressType type        // matches
String walletId         // additional field
int index               // matches
String? derivationPath  // additional field; null for Node addresses
```

`Address` carries every field `HdAddressEntry` carries, with one rename
(`address` → `value`). No missing-field gap. The two extra fields
(`walletId`, `derivationPath`) are already populated by
`HdAddressGenerationStrategy` in
`/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/src/application/hd_address_generation_strategy.dart`.

### Cycle check: would `transaction → address` introduce a cycle?

Current `packages/transaction/pubspec.yaml` dependencies (lines 11–13):

```
shared_kernel: path: ../shared_kernel
```

`address` is **not** declared. Adding it creates a new edge
`transaction → address`.

Reverse-direction grep — does `address` import from `transaction`?

- `grep -l "package:transaction" packages/address/` → 0 matches
- `grep -l "package:transaction" packages/wallet/` → 0 matches
- `grep -l "package:transaction" packages/keys/` → 0 matches

No back-edge exists. The new `transaction → address` edge produces a DAG:

```
shared_kernel ← keys ← wallet ← address ← transaction
                                            ↑
                                            └─ (new edge: transaction → address)
```

`bitcoin_node → transaction` and `bitcoin_node → address` already exist
(`packages/bitcoin_node/pubspec.yaml` lines 11–20); no change there.

### Call chain on the HD signing hot path

```
HdAddressDataSourceImpl (lib/core/adapters/hd_address_data_source_impl.dart)
  → reads AddressRepository.getAddresses(walletId)
  → maps each Address into HdAddressEntry  ← this conversion is what gets removed
  → returned to PrepareHdSendUseCase (packages/transaction/lib/src/application/prepare_hd_send_use_case.dart)
    → filters to AddressType.nativeSegwit
    → builds addressLookup keyed by entry.address (string)
    → constructs SigningInput { txid, vout, amountSat, address, derivationIndex, addressType }
    → returned in HdSendPreparation
  → SendHdTransactionUseCase passes SigningInput[] to TransactionSigner
    → HdTransactionSigner adapter (lib/core/adapters/hd_transaction_signer.dart)
    → calls keys/SignTransactionUseCase (only ever called inside keys)
```

After Phase 2: `HdAddressDataSource.getAddressesForWallet` returns
`List<Address>`; `addressLookup` is keyed by `Address.value`; everything
downstream stays type-equivalent because `Address.index` and
`Address.type` survive the rename.

### Reference vectors that must remain green

`packages/keys/test/key_derivation_service_impl_test.dart`,
`packages/keys/test/seed_repository_impl_test.dart`,
`packages/keys/test/bip39_service_impl_test.dart` — these are the BW-0003
reference vectors. None touch `HdAddressEntry`. They will only break if
`SigningInput` semantics drift, which they must not.

### DI registration sites unchanged in count

`/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/lib/core/di/app_dependencies_builder.dart`
constructs `HdAddressDataSourceImpl(repository: address.addressRepository)`
on line 72. The constructor signature does not change in Phase 2; only
the implementation body changes from `HdAddressEntry` mapping to direct
`Address` return. App-level DI requires no edit.

`packages/transaction/lib/transaction_assembly.dart` line 45 declares
`HdAddressDataSource hdAddressDataSource` — interface type unchanged;
only the generic `Future<List<X>>` return type changes upstream. No
edit required to the assembly.

---

## External Facts

- Dart workspace resolution must be re-run (`dart pub get`) after the
  `pubspec.yaml` change.
- `address` package public API (`packages/address/lib/address.dart`)
  already exports `src/domain/entity/address.dart`. No barrel change is
  needed in `address`.
- `transaction` package barrel
  (`packages/transaction/lib/transaction.dart`) currently exports
  `src/domain/value_object/hd_address_entry.dart`. After removal, the
  barrel must drop that line; no other transaction-package symbol is
  affected.

---

## Risks

| Risk | Impact | Recommendation |
|------|--------|----------------|
| Field rename `HdAddressEntry.address` → `Address.value` produces a silent type-correct but semantically wrong substitution at one of the five call sites | Could change which UTXO is matched to which signing input | Each `entry.address` access in `prepare_hd_send_use_case.dart` and `hd_address_data_source_impl.dart` must be rewritten to `.value`; reference-vector signing test must remain bit-identical |
| Equality semantics: `HdAddressEntry` had no value equality; the existing matching logic uses `address` as a `Map` key (string equality). `Address` likewise has no `==` override | None — equality is on the string value, not on the object | Document explicitly that the matching key remains `Address.value` (not `Address` itself); a unit test on the matching logic in `PrepareHdSendUseCase` is recommended but optional |
| `derivationPath` exposure widens. Today `HdAddressEntry` does not carry `derivationPath`; `Address` does (nullable) | Linkable HD metadata could leak into UI logs or RPC payloads if someone reads `Address.derivationPath` from new call sites | Security review must inspect every modified file for new reads of `Address.derivationPath`; only the existing `HdAddressGenerationStrategy` should write it; no consumer should newly read it |
| Adding `address: path: ../address` to `transaction/pubspec.yaml` re-runs workspace resolution; a transitive `keys` or `wallet` symbol could surface inside `transaction` and tempt premature use | Architectural drift outside Phase 2 scope | Limit imports inside `transaction/` to `package:address/address.dart`; do not import `package:wallet/` or `package:keys/` from `transaction/` in this phase |
| A test asserting on `HdAddressEntry` is deleted instead of rewritten | Coverage drop | Currently zero such tests exist (`grep` confirms); preserve that by not adding any HdAddressEntry-shaped test during this phase |
| Logging/telemetry call added that emits `Address.derivationPath` | Privacy regression (linkability) | Phase 2 security review must explicitly verify this; no new `developer.log` site touches `derivationPath` |

---

## Design Pressure

### Security-sensitive data paths

- The path that must remain bit-identical:
  `HdAddressDataSource → PrepareHdSendUseCase → SigningInput → HdTransactionSigner → keys/SignTransactionUseCase`.
  Phase 2 swaps the type at the upstream end (`HdAddressEntry` →
  `Address`); the downstream `SigningInput` constructor and all
  `keys/`-internal logic are unchanged.
- `Address.derivationPath` is non-secret but linkable. Today the field is
  read only inside `keys/SignTransactionUseCase` (after derivation by
  index). Reading it from the new call sites is forbidden — the existing
  signing flow uses `Address.index` and `Address.type` to re-derive the
  key, never the path string.
- Private key material (mnemonic, seed bytes, derived private keys, WIF)
  remains inside `packages/keys/`. `Address` does not carry any key
  material; this phase does not change that.

### Trust boundaries

- The HD trust boundary today: HD signing context is constructed inside
  `transaction/application/prepare_hd_send_use_case.dart` and consumed
  by `keys/` only via the `HdTransactionSigner` adapter at
  `lib/core/adapters/hd_transaction_signer.dart`.
- After Phase 2: the same boundary holds. `Address` is a domain entity
  in `address/`; it crosses package boundaries (now into `transaction/`)
  but not trust boundaries (no key material).
- What must NOT cross after the change: `Address.derivationPath` must not
  reach UI layers, RPC payloads, or telemetry. The security review must
  grep every modified file for `derivationPath` and confirm no new read.
- Signing-call sites stay inside the keys boundary. No new code path
  outside `packages/keys/` may sign as a side effect.

### Open architectural decisions (potential ADR follow-ups)

- Whether `Address` should gain value equality (`operator ==`) for the
  matching logic. PRD Open Q resolves this: only if strictly required.
  The current code uses string-keyed maps, so equality is not needed.
  No ADR required for Phase 2.
- Whether transaction-side address projections (e.g. "is this a change
  address?") belong in `address` or in `transaction`. PRD §Open Questions
  defaults to extending `Address` in its owner module. Not a Phase 2
  blocker.

---

## References

- Phase 2 PRD: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/BW-0005/prd/BW-0005-phase-2.prd.md`
- Architecture rules: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/project/conventions.md` (DataSource ownership; Prohibited list; "Never log or expose mnemonic/seed/private key material")
- Hot-path files:
  - `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/domain/value_object/hd_address_entry.dart` (delete)
  - `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/domain/data_sources/hd_address_data_source.dart` (return type)
  - `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/src/application/prepare_hd_send_use_case.dart` (rename `entry.address` → `value`; preserve `index`, `type`)
  - `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/lib/core/adapters/hd_address_data_source_impl.dart` (return `addresses` directly; remove the `.map((a) => HdAddressEntry(...))`)
  - `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/transaction/lib/transaction.dart` (drop the `hd_address_entry.dart` export)
- Address entity: `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/packages/address/lib/src/domain/entity/address.dart`
- Recommended verification commands the implementer should run:
  - `grep -rn "HdAddressEntry" packages/ lib/ test/` → empty (docs allowed)
  - `test ! -e packages/transaction/lib/src/domain/value_object/hd_address_entry.dart`
  - `grep -A2 'address:' packages/transaction/pubspec.yaml` → shows path entry
  - `dart pub get` → exit 0
  - `flutter analyze --fatal-infos --fatal-warnings` → exit 0
  - `flutter test` → green
  - `flutter test packages/keys/test/` → all BW-0003 reference vectors pass
  - `grep -n "derivationPath" packages/transaction/ lib/core/adapters/` → no new read site
