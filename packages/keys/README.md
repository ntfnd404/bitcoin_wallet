# keys

## Package type: Business

Owns everything related to BIP-39 mnemonic management, BIP-32/84 HD key
derivation, and transaction signing. The app layer never touches raw private
key bytes — all cryptographic operations are encapsulated here.

## Why a separate package

Signing boundary rule SB-7: `transaction` must not depend on `keys`. Keeping
keys in its own package enforces this at the pub workspace level.

## Internal structure

**Clean Architecture layers** — `domain/`, `application/`, `data/`.

```
lib/src/
  domain/
    data_source/          ← (reserved for future storage contracts)
    entity/               ← Mnemonic, AccountXpub, DerivedAddress, SigningInput/Output
    exception/            ← KeysException subtypes
    repository/           ← SeedRepository interface
    service/              ← Bip39Service, KeyDerivationService, TransactionSigningService
  application/            ← GetSeedUseCase, GetXpubUseCase, SignTransactionUseCase
  data/
    repository/           ← SeedRepositoryImpl
    service/              ← Bip39ServiceImpl, KeyDerivationServiceImpl,
    │                        TransactionSigningServiceImpl
    │                        bip39_wordlist.dart (word data used only by Bip39ServiceImpl)
    crypto/               ← private crypto primitives (BIP-32, ECDSA, sighash, tx builder)
```

### Why `data/` is split this way

`data/` subfolders mirror `domain/` subfolders — the folder name matches the
type of interface being implemented. `crypto/` has no domain interface; it is
a private implementation detail of the service impls.

## Public API

Barrel: `package:keys/keys.dart`
Assembly: `package:keys/keys_assembly.dart` — `KeysAssembly`

| Symbol | Kind | Description |
|---|---|---|
| `GetSeedUseCase` | class | Retrieves the stored mnemonic |
| `GetXpubUseCase` | class | Derives account xpub |
| `SignTransactionUseCase` | class | Signs a P2WPKH transaction |
| `Bip39Service` | abstract class | Mnemonic generation and validation |
| `KeyDerivationService` | abstract class | BIP-32/84 key derivation |
| `SeedRepository` | abstract class | Mnemonic persistence contract |
| `Mnemonic` | class | BIP-39 mnemonic phrase |
| `AccountXpub` | class | Account-level extended public key |
| `KeysException` | sealed class | Base for all keys exceptions |
| `KeysAssembly` | final class | DI factory |

## Signing boundary

Raw private-key bytes never cross the package boundary. See `conventions.md`
SB-1 through SB-7. Exception subtypes carry zero fields.

## Dependencies

Workspace packages: `shared_kernel`, `storage`.
Third-party: `crypto`, `pointycastle`.
