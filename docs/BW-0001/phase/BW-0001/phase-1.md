# Phase 1: Foundation

Status: `TASKLIST_READY`
Ticket: BW-0001
Goal: Prepare the project for development — dependencies, folder structure, RPC client.

Session brief — read this file only to have full context for this work session.

---

## Context

### Why this phase exists

The project starts with `lib/main.dart` — Hello World with no architecture.
Before writing domain logic, BLoC, and UI, we need to:
- add all dependencies,
- create the folder structure per conventions,
- write a basic RPC client that will serve as the foundation for Node Wallet.

### What this unlocks

After Phase 1, the following become possible:
- **Phase 2** — domain models and repository interfaces (folder structure required)
- **Phase 3** — NodeWalletRepositoryImpl (BitcoinRpcClient required)
- **Phase 4** — HD Wallet (crypto, pointycastle, flutter_secure_storage required)

### Key constraints

- Exact versions without `^` (`crypto: 3.0.7`, `pointycastle: 4.0.0`, not `^2.2.0`)
- Dependencies sorted alphabetically in pubspec.yaml
- RPC endpoint: `http://bitcoin:bitcoin@127.0.0.1:18443`
- Never use `!` operator or `print` in code
- One class = one file
- Functions: up to 20 lines, single responsibility

### Technologies

| Technology | Package | Role |
|------------|---------|------|
| HTTP client | `dart:io` / `http` (flutter built-in) | JSON-RPC requests to Bitcoin Core |
| BIP39 / HD keys | `crypto: 3.0.7` + `pointycastle: 4.0.0` | Address derivation, all types, regtest |
| State management | `flutter_bloc: 9.1.1` | BLoC pattern |
| Secure storage | `flutter_secure_storage: 10.0.0` | Seed phrase and wallet metadata storage |
| Navigation | Flutter built-in Navigator | Screen routing via Navigator.push/pop |

---

## Tasks

### `pubspec.yaml`

- [x] 1.1 Add all dependencies
  Acceptance: `flutter pub get` completes without errors; all packages visible on all platforms

### `lib/` folder structure

- [x] 1.2 Create directory structure
  Acceptance: structure matches `docs/BW-0001/vision-BW-0001.md`

### `packages/rpc_client/lib/src/bitcoin_rpc_client.dart`

- [x] 1.3 Implement BitcoinRpcClient
  Acceptance: calling `getblockchaininfo` returns `chain: regtest`

### After changes

- [x] Run `flutter analyze` — zero warnings/infos
- [x] Format changed files: `dart format lib/`

---

## Acceptance Criteria

- `flutter pub get` — success, no version conflicts
- `lib/` structure matches vision-BW-0001.md (folders only; files are added in subsequent phases)
- `BitcoinRpcClient.call('getblockchaininfo')` returns `{'chain': 'regtest', ...}`
- `flutter analyze` — zero warnings and errors
- Credentials are not hardcoded outside `AppConstants`

---

## Dependencies

No prior phases required. Phase 1 is first.

---

## Technical Details

### pubspec.yaml — final dependencies section

```yaml
dependencies:
  crypto: 3.0.7
  pointycastle: 4.0.0
  flutter:
    sdk: flutter
  flutter_bloc: 9.1.1
  flutter_secure_storage: 10.0.0
  json_annotation: 4.11.0
  uuid: 4.5.3

dev_dependencies:
  flutter_lints: ^6.0.0
  flutter_test:
    sdk: flutter
  json_serializable: 6.13.1
```

### BitcoinRpcClient — skeleton

```dart
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class BitcoinRpcClient {
  final http.Client _client;

  BitcoinRpcClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> call(
    String method, [
    List<dynamic> params = const [],
  ]) async {
    final response = await _client.post(
      Uri.parse(AppConstants.rpcUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(
          utf8.encode('${AppConstants.rpcUser}:${AppConstants.rpcPassword}'),
        )}',
      },
      body: jsonEncode({
        'jsonrpc': '1.0',
        'id': method,
        'method': method,
        'params': params,
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final error = body['error'];
    if (error != null) {
      throw RpcException(method, error as Map<String, dynamic>);
    }
    return body['result'] as Map<String, dynamic>;
  }
}

class RpcException implements Exception {
  final String method;
  final Map<String, dynamic> error;
  const RpcException(this.method, this.error);

  @override
  String toString() => 'RpcException[$method]: ${error['message']}';
}
```

### AppConstants (sketch for Phase 1)

```dart
// lib/core/constants/app_constants.dart
abstract final class AppConstants {
  static const String rpcUrl = 'http://127.0.0.1:18443';
  static const String rpcUser = 'bitcoin';
  static const String rpcPassword = 'bitcoin';
}
```

### Note: `http` package

`flutter` already includes `http` transitively through the Flutter SDK — do not add it separately.
`BitcoinRpcClient` imports `package:http/http.dart`.
