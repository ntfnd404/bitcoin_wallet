# storage

## Package type: Adapter (platform)

Flutter implementation of the `SecureStorage` contract from `shared_kernel`.
Wraps `flutter_secure_storage` so domain and application packages stay
independent of the Flutter SDK. No business logic.

## Internal structure

**Flat.** Two files — one re-export shim, one implementation.

```
lib/src/
  secure_storage_impl.dart  ← FlutterSecureStorage-backed SecureStorageImpl
```

### Why flat

Single-concern adapter with one implementation class. No hierarchy needed.

## Public API

Barrel: `package:storage/storage.dart`

| Symbol | Kind | Description |
|---|---|---|
| `SecureStorageImpl` | final class | `flutter_secure_storage`-backed `SecureStorage` |
| `SecureStorageException` | class | Thrown on read/write failures |

## Dependencies

Workspace packages: `shared_kernel`.
Third-party: `flutter_secure_storage: 10.0.0`.
SDK: Flutter SDK.
