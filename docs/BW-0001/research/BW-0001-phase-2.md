# Research: BW-0001 Phase 2 — Domain Models & Interfaces

Status: `RESEARCH_DONE`
Ticket: BW-0001

---

## Investigation

### Current codebase state

Phase 1 delivered a working foundation. The following files are relevant to Phase 2:

**Flutter app (`lib/`):**
- `lib/main.dart` — `runZonedGuarded` + `AppDependenciesBuilder().build()` + `runApp(App(...))`. Ready.
- `lib/app.dart` — `AppScope` (`InheritedWidget`) + `App` (`StatelessWidget`). Both exist and compile. Task 2.5 is **already done**.
- `lib/core/di/app_dependencies.dart` — `final class AppDependencies { const AppDependencies(); }`. Empty container, ready to receive typed fields.
- `lib/core/di/app_dependencies_builder.dart` — `AppDependenciesBuilder.build()` returns `const AppDependencies()`. Ready.
- `lib/core/constants/app_constants.dart` — `abstract final class AppConstants` with `rpcUrl`, `rpcUser`, `rpcPassword`. Derivation path constants are **missing** — must be added in task 2.4.

**Domain package (`packages/domain/`):**
- `packages/domain/pubspec.yaml` — `sdk: ^3.11.3`, `resolution: workspace`, **zero dependencies**. Correct.
- `packages/domain/lib/domain.dart` — barrel file with all exports commented out. Must be uncommented as files are created.
- `packages/domain/lib/src/entity/` — empty (`.gitkeep` only). Must be populated in task 2.1.
- `packages/domain/lib/src/repository/` — empty. Must be populated in task 2.2.
- `packages/domain/lib/src/service/` — empty. Must be populated in task 2.3.

**Data package (`packages/data/`):**
- `packages/data/pubspec.yaml` — depends on `domain`, `rpc_client`, `storage`, `crypto`, `pointycastle`. Correct.
- `packages/data/lib/src/repository/` and `service/` — empty placeholders. Not touched in Phase 2.

**Infrastructure packages (already complete):**
- `packages/rpc_client/lib/src/bitcoin_rpc_client.dart` — `BitcoinRpcClient` with `call(String, [List<Object>])` → `Map<String, Object?>`.
- `packages/storage/lib/src/secure_storage.dart` — `SecureStorage` with `write`/`read`/`delete`.

### Dart language features investigated

**`abstract interface class` (Dart 3.0+)**
The project uses Dart `^3.11.3`. `abstract interface class` is fully supported. This modifier combination:
- Forbids instantiation (abstract).
- Forbids extension outside the library (interface — implementors must use `implements`, not `extends`).
- Requires every method to be overridden by implementing classes.
This is the correct pattern for repository and service interfaces.

**`final class` for entities**
`final class` (Dart 3.0+) prevents extension and mixin application. Combined with `const` constructors and immutable `final` fields, this is the correct pattern for domain value objects. No code generation (`freezed`) is used — the project convention explicitly prohibits it for domain entities.

**`copyWith` pattern without code generation**
Manual `copyWith` on a `final class` uses named optional parameters (all nullable) and falls back to `this.<field>` when `null` is passed. One subtlety: if a field is itself nullable (`String?`), a plain `String? value` parameter cannot distinguish "caller passed null intentionally" from "caller passed nothing". For Phase 2 entities, only `Address.derivationPath` is nullable. The accepted solution is an `Object? _sentinel` pattern or simply accepting the limitation for this demo project. Given the PRD does not require clearing nullable fields via `copyWith`, the simple nullable-parameter approach is sufficient.

**`Mnemonic` opaqueness strategy**
`Mnemonic` must not override `toString()`. By default, `Object.toString()` returns `Instance of 'Mnemonic'` — no seed words are exposed. The class must not implement `toString`, must not extend any class that does, and must not be passed to string interpolation sites that would reveal its fields. The `words` field is `List<String>` — readable within the domain/data layer by design, but not surfaced to presentation as a string.

**`WalletType` and `AddressType` enums**
Plain Dart enums (not enhanced enums with methods or fields) — sufficient for the domain layer. Enhanced enum capabilities are available if needed in later phases.

### Domain barrel file

`packages/domain/lib/domain.dart` currently has all exports commented out. The Implementer must uncomment each export as the corresponding file is created. The barrel is the only public surface of the `domain` package — consuming packages (`data`, `lib/`) import `package:domain/domain.dart` only.

Note: the barrel currently references `src/entity/utxo.dart` which is out of scope for Phase 2. That line must remain commented.

### `AppConstants` — derivation paths

The four BIP paths for regtest (`coin_type = 1`):
- `m/44'/1'/0'/0` — Legacy P2PKH (the `/n` index part is appended at derivation time, not stored as a constant)
- `m/49'/1'/0'/0` — Wrapped SegWit P2SH-P2WPKH
- `m/84'/1'/0'/0` — Native SegWit P2WPKH
- `m/86'/1'/0'/0` — Taproot P2TR

These are account-level paths (without the address index). The address index `n` is appended as `/<index>` by `KeyDerivationService.deriveAddress` at call time. Storing the account-level path as a constant is the correct design.

### AppDependencies fields

Phase 2 defines the interfaces but no implementations yet. `AppDependencies` will gain typed fields:
- `WalletRepository walletRepository`
- `SeedRepository seedRepository`
- `Bip39Service bip39Service`
- `KeyDerivationService keyDerivationService`

These fields will be populated in Phases 3–4. For Phase 2, `AppDependenciesBuilder.build()` must return stub implementations that throw `UnimplementedError`. The stubs live inside `app_dependencies_builder.dart` as private inner classes or inline anonymous implementations — they are not part of the domain package.

However, the PRD states Task 2.5 (DI scaffold) is already done. Looking at the current `app_dependencies.dart`, the container is empty with no fields yet. The existing `AppScope` and `App` wiring is complete, so 2.5 is done at the infrastructure level. The fields in `AppDependencies` and stub implementations in `AppDependenciesBuilder` are the remaining sub-tasks of 2.5 that must be completed when the interfaces exist.

---

## Key Decisions

| Decision | Rationale | Alternatives |
|----------|-----------|--------------|
| `final class` for entities | Prevents unintended extension; documents intent of immutability; Dart 3 idiomatic | Plain `class` — too permissive; `@immutable` annotation — not enforced by compiler |
| `const` constructors on all entities | Enables compile-time constants, eliminates object identity surprises in tests | Non-const — no upside |
| Manual `copyWith` without code generation | Project convention — no `freezed`; demonstrates OOP knowledge | `freezed` — hides derivation; `built_value` — heavy |
| `abstract interface class` for repositories and services | Dart 3 native; compiler enforces all methods at every implementation site | `abstract class` — permits partial implementation via `extends`; defeats the interface contract |
| `Mnemonic.words` as `List<String>` | Matches BIP39 structure (words, not raw entropy); accessible within domain/data for seed computation | `String` — joins words, risks logging; `Uint8List` — raw entropy, loses word structure |
| No `toString()` on `Mnemonic` | Security — prevents accidental logging in `log()`, `print()`, string interpolation | Override with `'[REDACTED]'` — acceptable alternative, but omission is simpler and equally safe |
| `Address.derivationPath` nullable | Node Wallet addresses have no derivation path (Bitcoin Core holds keys) | Separate `NodeAddress` / `HdAddress` types — over-engineering for demo scope |
| Account-level derivation path constants | Index `n` is dynamic; the account path is the stable constant | Full path template with `{index}` placeholder — harder to use, no benefit |
| Stub `UnimplementedError` implementations in `AppDependenciesBuilder` | Keeps app compilable and launchable before Phases 3–4; clear error if accidentally called | Null fields in `AppDependencies` — causes null-pointer at runtime with no message |

---

## Technical Details

### Entity signatures

```dart
// packages/domain/lib/src/entity/wallet_type.dart
enum WalletType { node, hd }

// packages/domain/lib/src/entity/address_type.dart
enum AddressType { legacy, wrappedSegwit, nativeSegwit, taproot }

// packages/domain/lib/src/entity/wallet.dart
final class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String name;
  final WalletType type;
  final DateTime createdAt;

  Wallet copyWith({
    String? id,
    String? name,
    WalletType? type,
    DateTime? createdAt,
  }) => Wallet(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
  );
}

// packages/domain/lib/src/entity/address.dart
final class Address {
  const Address({
    required this.value,
    required this.type,
    required this.walletId,
    required this.index,
    this.derivationPath,  // null for Node Wallet
  });

  final String value;
  final AddressType type;
  final String walletId;
  final int index;
  final String? derivationPath;

  Address copyWith({
    String? value,
    AddressType? type,
    String? walletId,
    int? index,
    String? derivationPath,
  }) => Address(
    value: value ?? this.value,
    type: type ?? this.type,
    walletId: walletId ?? this.walletId,
    index: index ?? this.index,
    derivationPath: derivationPath ?? this.derivationPath,
  );
}

// packages/domain/lib/src/entity/mnemonic.dart
final class Mnemonic {
  const Mnemonic({required this.words});

  final List<String> words;

  // No toString() override — Object.toString() returns 'Instance of Mnemonic'
  // preventing accidental logging of seed words.
}
```

### Repository interface signatures

```dart
// packages/domain/lib/src/repository/wallet_repository.dart
abstract interface class WalletRepository {
  /// Returns all wallets persisted on this device.
  Future<List<Wallet>> getWallets();

  /// Creates a new Node Wallet via Bitcoin Core RPC `createwallet`.
  ///
  /// Throws [UnsupportedError] if called on an HD-only implementation.
  Future<Wallet> createNodeWallet(String name);

  /// Creates a new HD Wallet, generates a BIP39 mnemonic, stores the seed,
  /// and returns both the wallet metadata and the mnemonic.
  ///
  /// [wordCount] must be 12 or 24.
  /// Throws [UnsupportedError] if called on a Node-only implementation.
  Future<(Wallet, Mnemonic)> createHDWallet(String name, {int wordCount = 12});

  /// Restores an HD Wallet from an existing [mnemonic] after BIP39 validation.
  ///
  /// Throws [ArgumentError] if [mnemonic] fails BIP39 checksum validation.
  /// Throws [UnsupportedError] if called on a Node-only implementation.
  Future<Wallet> restoreHDWallet(String name, Mnemonic mnemonic);

  /// Generates the next address of [type] for [wallet].
  ///
  /// For Node Wallet: calls RPC `getnewaddress`.
  /// For HD Wallet: derives the key at the next unused index.
  Future<Address> generateAddress(Wallet wallet, AddressType type);

  /// Returns all addresses previously generated for [wallet].
  Future<List<Address>> getAddresses(Wallet wallet);
}

// packages/domain/lib/src/repository/seed_repository.dart
abstract interface class SeedRepository {
  /// Persists [mnemonic] for [walletId] in secure storage.
  ///
  /// Overwrites any existing seed for this wallet.
  Future<void> storeSeed(String walletId, Mnemonic mnemonic);

  /// Returns the [Mnemonic] for [walletId], or `null` if none is stored.
  Future<Mnemonic?> getSeed(String walletId);

  /// Deletes the stored seed for [walletId].
  ///
  /// No-op if no seed exists for this wallet.
  Future<void> deleteSeed(String walletId);
}
```

### Service interface signatures

```dart
// packages/domain/lib/src/service/bip39_service.dart
abstract interface class Bip39Service {
  /// Generates a BIP39 mnemonic with [wordCount] words (12 or 24).
  ///
  /// Uses a cryptographically secure random source.
  /// Throws [ArgumentError] if [wordCount] is not 12 or 24.
  Mnemonic generateMnemonic({int wordCount = 12});

  /// Returns `true` if [mnemonic] is a valid BIP39 mnemonic (checksum passes).
  bool validateMnemonic(Mnemonic mnemonic);
}

// packages/domain/lib/src/service/key_derivation_service.dart
abstract interface class KeyDerivationService {
  /// Derives a Bitcoin address from [mnemonic] at the given [type] and [index].
  ///
  /// Paths (regtest, coin_type=1):
  ///   legacy          → m/44'/1'/0'/0/[index]
  ///   wrappedSegwit   → m/49'/1'/0'/0/[index]
  ///   nativeSegwit    → m/84'/1'/0'/0/[index]
  ///   taproot         → m/86'/1'/0'/0/[index]
  ///
  /// [index] must be >= 0.
  Address deriveAddress(Mnemonic mnemonic, AddressType type, int index);
}
```

### AppConstants — derivation path additions

```dart
// lib/core/constants/app_constants.dart  (additions only)
abstract final class AppConstants {
  static const String rpcUrl = 'http://127.0.0.1:18443';
  static const String rpcUser = 'bitcoin';
  static const String rpcPassword = 'bitcoin';

  // BIP44/49/84/86 account-level paths — regtest (coin_type = 1)
  // Append '/<index>' for the final child key.
  static const String derivationPathLegacy        = "m/44'/1'/0'/0";
  static const String derivationPathWrappedSegwit = "m/49'/1'/0'/0";
  static const String derivationPathNativeSegwit  = "m/84'/1'/0'/0";
  static const String derivationPathTaproot       = "m/86'/1'/0'/0";
}
```

### AppDependencies with typed fields

```dart
// lib/core/di/app_dependencies.dart
import 'package:domain/domain.dart';

final class AppDependencies {
  const AppDependencies({
    required this.walletRepository,
    required this.seedRepository,
    required this.bip39Service,
    required this.keyDerivationService,
  });

  final WalletRepository walletRepository;
  final SeedRepository seedRepository;
  final Bip39Service bip39Service;
  final KeyDerivationService keyDerivationService;
}
```

### Stub implementations in AppDependenciesBuilder

Stub inner classes in `app_dependencies_builder.dart` throw `UnimplementedError` on every method. They are private, named `_StubWalletRepository` etc., and referenced only from `AppDependenciesBuilder.build()`. This ensures the app compiles and launches without real implementations and fails loudly (not silently with a null-pointer) if any domain method is accidentally called before Phase 3.

---

## Risks Identified

| Risk | Impact | Recommendation |
|------|--------|----------------|
| `Address.copyWith` cannot clear `derivationPath` to `null` via the simple nullable param pattern | Low | Acceptable for demo scope — no use case requires setting derivationPath to null after creation. Document in code comment. |
| `domain.dart` barrel references `utxo.dart` (commented out) — Phase 2 Implementer may be confused | Low | Leave the line commented; add a note that `utxo.dart` is Phase 4 scope. |
| Stub `UnimplementedError` from `AppDependenciesBuilder` surfacing in UI before Phases 3–4 | Medium | Stubs are intentional; ensure the app only calls domain methods from BLoC (Phase 5+). The stubs will not be called in Phase 2 because no BLoC exists yet. |
| `List<String>` in `Mnemonic.words` is mutable — caller could mutate the list after construction | Low | Domain convention: callers must not modify the list. `List.unmodifiable` wrapper can be added in Phase 4 `Bip39ServiceImpl` when the list is produced. |

---

## References

- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/BW-0001/vision-BW-0001.md`
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/BW-0001/prd/BW-0001-phase-2.prd.md`
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/project/conventions.md`
- `/Users/olegosipov/Documents/Projects/bitcoin_wallet/bitcoin_wallet/docs/project/code-style-guide.md`
- Dart 3 language spec: `final class`, `abstract interface class`, `const` constructors
