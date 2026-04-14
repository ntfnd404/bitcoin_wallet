# BW-0001-2: Domain Models & Interfaces

Status: `PRD_READY`
Ticket: BW-0001
Phase: 2 of 7

---

## Context / Idea

BW-0001 introduces wallet creation and address generation for a Flutter Bitcoin wallet app backed
by a local Bitcoin Core regtest node.

Phase 1 laid the foundation: dependencies, folder scaffold, and a working `BitcoinRpcClient`.
The app still has no business logic — no wallets, no addresses, no key management.

Phase 2 establishes the **domain layer**: the shared vocabulary of types and contracts that every
other layer (data, presentation) will depend on. Nothing is implemented yet; this phase defines
what must exist and what each piece must guarantee.

Reference: `docs/BW-0001/idea-BW-0001.md`, `docs/BW-0001/vision-BW-0001.md`

---

## Goals

1. Define all domain entities (`WalletType`, `AddressType`, `Wallet`, `Address`, `Mnemonic`) as
   immutable, `const`-constructable value types with `copyWith`.
2. Define repository interfaces (`WalletRepository`, `SeedRepository`) that abstract storage and
   wallet lifecycle for both custodial and non-custodial wallets.
3. Define service interfaces (`Bip39Service`, `KeyDerivationService`) that abstract BIP39 mnemonic
   management and HD key derivation.
4. Centralise all configuration constants (RPC connection details, derivation paths) in
   `AppConstants` — no magic strings or numbers anywhere in the codebase.
5. Provide a DI scaffold (`AppDependencies`, `AppDependenciesBuilder`, `AppScope`) so the app
   compiles and launches with an accessible dependency container, ready to receive implementations
   in Phases 3–4.

---

## User Stories

**As a developer implementing the data layer**, I need a stable set of domain interfaces and
entities so that I can write implementations without touching other layers.

**As a developer implementing the BLoC layer**, I need clearly defined domain entities so that
state classes can reference `Wallet`, `Address`, and `Mnemonic` without depending on any
infrastructure.

**As a developer wiring up the app**, I need `AppConstants` to hold all RPC credentials and
derivation paths so that no magic string ever appears in application code.

**As a developer running the app**, I need the DI scaffold to be in place so that the app compiles
and launches — even before any real implementations exist — and `AppScope.of(context)` is
accessible anywhere in the widget tree.

---

## Main Scenarios

### Scenario 1: Domain entity construction and mutation

- A domain entity (`Wallet`, `Address`, or `Mnemonic`) is instantiated with all required fields.
- `copyWith` is called to produce a new instance with one field changed.
- Expected result: the original instance is unchanged; the new instance has the updated field; both
  instances are equal to themselves under value equality.

### Scenario 2: Mnemonic does not expose its words as a string

- A `Mnemonic` instance is created with a list of words.
- Code attempts to obtain a string representation by calling `toString()` or by implicitly
  converting the instance (e.g. string interpolation, logger output).
- Expected result: no BIP39 word sequence appears in the output; the sensitive data is not
  accidentally serialised or logged.

### Scenario 3: Repository interface contract is satisfied by any implementation

- A class claims to implement `WalletRepository`.
- The Dart compiler verifies the class at compile time.
- Expected result: missing methods or wrong signatures are compile errors, not runtime failures.

### Scenario 4: Service interface contract enforces derivation signature

- A class claims to implement `KeyDerivationService`.
- `deriveAddress(mnemonic, type, index)` is called with a valid `Mnemonic`, a valid `AddressType`,
  and a non-negative integer index.
- Expected result: any conforming implementation returns an `Address`; the interface does not
  prescribe the algorithm.

### Scenario 5: AppConstants provides all derivation paths

- Code in the data or presentation layer needs the BIP44/49/84/86 derivation path template for a
  given `AddressType`.
- Expected result: the path is retrieved from `AppConstants` as a named constant; no path string
  is hard-coded at the call site.

### Scenario 6: App launches with DI scaffold in place

- The app is started with stub implementations (or no real implementations yet) wired through
  `AppDependenciesBuilder`.
- `AppScope` wraps the widget tree.
- Expected result: the app compiles without errors, reaches the first screen, and
  `AppScope.of(context)` returns the dependency container without throwing.

### Scenario 7: Unsupported operation on wrong wallet type

- A caller invokes an HD-specific method (e.g. seed retrieval) on a `WalletRepository`
  implementation that backs a Node Wallet.
- Expected result: an `UnsupportedError` is thrown with a descriptive message; the error is
  defined in the interface contract via documentation.

---

## Success / Metrics

| Criterion | Verification |
|-----------|--------------|
| All five entity files exist in `packages/domain/lib/src/entity/` | File presence check |
| Each entity has a `const` constructor and a `copyWith` method | Code review |
| `Mnemonic` has no `toString()` override | Code review; `flutter analyze` |
| `WalletRepository` and `SeedRepository` are `abstract interface class` with doc comments on every method | Code review |
| `Bip39Service` and `KeyDerivationService` are `abstract interface class` with no implementation | Code review |
| `AppConstants` contains `rpcUrl`, `rpcUser`, `rpcPassword`, and one derivation-path constant per `AddressType` | Code review |
| No magic strings or magic numbers appear in `AppConstants` consumers | `flutter analyze` + code review |
| `AppDependencies` is an immutable container with fields typed as domain interfaces | Code review |
| `AppScope` is an `InheritedWidget`; `AppScope.of(context)` compiles and is accessible in the widget tree | Manual launch on macOS |
| `flutter analyze` reports zero warnings or errors across all changed files | CI / manual run |

---

## Constraints and Assumptions

- The `domain` package must have **zero dependencies** — no Flutter SDK, no third-party packages.
  Only pure Dart.
- All entities must be **immutable** (`final` fields, `const` constructors). Mutation is expressed
  via `copyWith`, never by reassigning fields.
- `Mnemonic` must **not** implement or override `toString()`. This prevents accidental logging of
  seed words.
- Repository and service types are **interfaces only** (`abstract interface class`). No
  implementation code belongs in this package.
- `AppConstants` lives in `lib/core/constants/` inside the Flutter app, not in `packages/domain`.
  It may reference `AddressType` but must not reach into the data layer.
- The DI scaffold (`AppDependencies`, `AppDependenciesBuilder`) may use stub/null implementations
  for domain interfaces until Phases 3–4 fill them in.
- Regtest is the only target network: `coin_type = 1`, address prefixes `m`, `2`, `bcrt1q`,
  `bcrt1p`.
- Private keys must never be exposed outside the data/domain layer. This phase has no key
  material, so this constraint is preparatory — it shapes interface design (e.g. `Mnemonic` is
  opaque).

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Entity field set changes as later phases expose new requirements | Medium | Low | `copyWith` makes additive changes backward-compatible; breaking changes are explicit |
| `AppDependenciesBuilder` stub causes a null-pointer at runtime before real impls are wired | Low | Medium | Use placeholder implementations that throw `UnimplementedError` with a clear message rather than leaving fields null |
| `abstract interface class` semantics misunderstood — method added to interface but not all impls updated | Low | High | All interface methods must have doc comments; compiler enforces contract at every implementation site |

---

## Resolved Questions

- **Manual BIP39/BIP32 implementation vs. a library**: decided to implement manually using
  `crypto` and `pointycastle`. The goal of the project is to demonstrate knowledge of Bitcoin
  standards, not abstract it away. (Supersedes ADR-001 / coinlib.)
- **12 vs 24 words**: default is 12 for demo; 24 is supported via `wordCount` parameter on
  `Bip39Service.generateMnemonic`.
- **Regtest coin_type**: confirmed as `1` for all derivation paths.
- **`WalletRepository` split**: a single `WalletRepository` interface covers both Node Wallet and
  HD Wallet operations. Node Wallet implementations throw `UnsupportedError` on HD-specific
  methods; HD implementations throw `UnsupportedError` on node-specific operations that require
  RPC. This keeps the interface unified while the implementations are type-specialised.

---

## Open Questions

- None.
