# keys

## Purpose

BIP-standard key management module. Responsible for mnemonic generation and
validation (BIP-39), hierarchical-deterministic key derivation (BIP-32/BIP-44),
and PSBT transaction signing. Does not orchestrate HD wallet state; that
responsibility belongs to the `wallet` package.

Assembly entry point: `package:keys/keys_assembly.dart` — `KeysAssembly`.

## Public API

Barrel: `package:keys/keys.dart`

### Use cases

| Symbol | Kind | Description |
|---|---|---|
| `GetXpubUseCase` | class | Derives and returns the account-level xpub for a given wallet |
| `SignTransactionUseCase` | class | Signs a PSBT using the stored seed |

### Domain entities

| Symbol | Kind | Description |
|---|---|---|
| `AccountXpub` | class | Account-level extended public key value object |
| `DerivedAddress` | class | Address derived from a specific derivation path |
| `Mnemonic` | class | BIP-39 mnemonic phrase value object |
| `SigningInput` | class | Input descriptor for transaction signing |
| `SigningOutput` | class | Signed transaction result |

### Domain repository

| Symbol | Kind | Description |
|---|---|---|
| `SeedRepository` | abstract class | Persists and retrieves the encrypted seed |

### Domain services

| Symbol | Kind | Description |
|---|---|---|
| `Bip39Service` | abstract class | Mnemonic generation and validation |
| `KeyDerivationService` | abstract class | BIP-32/BIP-44 key derivation |
| `TransactionSigningService` | abstract class | Low-level PSBT signing |

### Assembly

| Symbol | Kind | Description |
|---|---|---|
| `KeysAssembly` | final class | Wires all implementations; exposes `getXpub` and `signTransaction` |

## Dependencies

Workspace packages: `shared_kernel`.
Third-party: `crypto: 3.0.7`, `pointycastle: 4.0.0`.
SDK: Dart SDK only.

## When to add here

Add a symbol only when it is a BIP-standard cryptographic primitive, a key
derivation concern, or a signing concern. Never add HD wallet orchestration
(wallet creation, wallet persistence, address generation strategies) — those
belong in `wallet` or `address`.

## Layer layout

```
lib/
  keys.dart                   # barrel
  keys_assembly.dart          # DI factory
  src/
    application/
      get_xpub_use_case.dart
      sign_transaction_use_case.dart
    data/
      bip39_service_impl.dart
      key_derivation_service_impl.dart
      seed_repository_impl.dart
      transaction_signing_service_impl.dart
    domain/
      entity/
        account_xpub.dart
        derived_address.dart
        mnemonic.dart
        signing_input.dart
        signing_output.dart
      repository/
        seed_repository.dart
      service/
        bip39_service.dart
        key_derivation_service.dart
        transaction_signing_service.dart
```
