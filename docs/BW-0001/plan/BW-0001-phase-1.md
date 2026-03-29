# Plan: BW-0001 Phase 1 — Foundation

Status: `PLAN_APPROVED`
Ticket: BW-0001

---

## Phase Scope

Prepare the project for architectural development: add dependencies, create the `lib/` folder structure, write `BitcoinRpcClient` and `AppConstants`. After this phase the project compiles, `flutter analyze` is clean, and the first RPC call to the local node can be made.

---

## Components

### `pubspec.yaml` (modified)

**Current state:** only `flutter` SDK + `flutter_lints`, `flutter_test`. Lines 9–19.

**Changes:**
- Add 6 runtime dependencies (alphabetical order, exact versions)
- Add 1 dev dependency (json_serializable)

**Resulting code:**

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

---

### `lib/` folder structure (created)

**Current state:** only `lib/main.dart`.

**Changes:** create empty directories (`.gitkeep` not needed — files will appear in subsequent phases):

```
lib/
├── core/
│   └── constants/
├── data/
│   ├── api/
│   ├── repository/
│   ├── service/
│   └── storage/
├── domain/
│   ├── model/
│   ├── repository/
│   └── service/
├── feature/
│   └── wallet/
│       ├── bloc/
│       ├── di/
│       └── view/
├── routing/
└── view/
```

Dart does not support empty folders in git — the first files in each directory are created together with them in Phase 2+. The structure is created alongside the first files in each directory.

---

### `lib/core/constants/app_constants.dart` (created)

**Current state:** file does not exist.

**Resulting code:**

```dart
abstract final class AppConstants {
  static const String rpcUrl = 'http://127.0.0.1:18443';
  static const String rpcUser = 'bitcoin';
  static const String rpcPassword = 'bitcoin';
}
```

---

### `packages/rpc_client/lib/src/bitcoin_rpc_client.dart` (created)

**Current state:** file does not exist.

**Resulting code:**

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
    final credentials = base64Encode(
      utf8.encode('${AppConstants.rpcUser}:${AppConstants.rpcPassword}'),
    );
    final response = await _client.post(
      Uri.parse(AppConstants.rpcUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $credentials',
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

---

## API Contract

```dart
// The only public method of the client
Future<Map<String, dynamic>> BitcoinRpcClient.call(
  String method, [
  List<dynamic> params = const [],
]);

// Exception thrown on RPC error
class RpcException implements Exception {
  final String method;
  final Map<String, dynamic> error;
}
```

---

## Data Flows

```
Flutter code
  → BitcoinRpcClient.call('getblockchaininfo')
  → HTTP POST http://127.0.0.1:18443
    headers: Authorization: Basic <base64(bitcoin:bitcoin)>
    body: {"jsonrpc":"1.0","id":"getblockchaininfo","method":"getblockchaininfo","params":[]}
  ← HTTP 200 {"result": {"chain":"regtest",...}, "error": null, "id": "getblockchaininfo"}
  → return body['result']
```

---

## NFR

| Requirement | Verification |
|-------------|--------------|
| Zero analyzer warnings | `flutter analyze --fatal-warnings` |
| Exact dependency versions | grep `^` in pubspec.yaml — must not appear on new packages |
| No `print` | `flutter analyze` will catch it, or grep |
| No `!` operator | code review |

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Version conflict between crypto/pointycastle | Low | Low | Standard packages, well tested |
| `http` package not available without explicit addition | Low | Medium | `flutter` SDK includes `http` transitively; if not — add explicitly |
| Bitcoin Core node not running during RPC test | Medium | Low | Run `make btc-up && make btc-wallet-ready` before testing |

---

## Implementation Steps

1. Update `pubspec.yaml` — add dependencies
2. Run `flutter pub get`
3. Create `lib/core/constants/app_constants.dart`
4. Create `packages/rpc_client/lib/src/bitcoin_rpc_client.dart`
5. Run `flutter analyze` — verify no warnings
6. Format: `dart format lib/`
7. Verify RPC manually (node must be running: `make btc-up`)

---

## Open Questions

None.
