# storage

## Purpose

Concrete Flutter implementation of the `SecureStorage` contract defined in
`shared_kernel`. Wraps `flutter_secure_storage` so that domain and application
packages remain independent of the Flutter SDK. Contains no business logic.

## Public API

Barrel: `package:storage/storage.dart`

| Symbol | Kind | Description |
|---|---|---|
| `SecureStorage` | abstract class | Re-exported from `shared_kernel` for backward compatibility during migration |
| `SecureStorageImpl` | final class | `FlutterSecureStorage`-backed implementation of `SecureStorage` |
| `FlutterSecureStorage` | class | Re-exported from `flutter_secure_storage` for consumer convenience |

## Dependencies

Workspace packages: `shared_kernel`.
Third-party: `flutter_secure_storage: 10.0.0`, `meta: ^1.17.0`.
SDK: Flutter SDK.

## When to add here

Add a symbol only when it is a concrete secure-storage implementation or an
adapter that bridges the Flutter SDK to the `SecureStorage` contract. Never add
business logic, domain entities, or repository abstractions.

## Layer layout

```
lib/
  storage.dart                # barrel
  src/
    secure_storage.dart       # re-exports SecureStorage from shared_kernel
    secure_storage_impl.dart  # FlutterSecureStorage-backed implementation
```
