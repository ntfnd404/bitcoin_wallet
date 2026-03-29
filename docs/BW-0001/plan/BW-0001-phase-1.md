# Plan: BW-0001 Phase 1 — Foundation

Status: `PLAN_APPROVED`
Ticket: BW-0001

---

## Phase Scope

Подготовить проект к архитектурной разработке: добавить зависимости, создать структуру папок `lib/`, написать `BitcoinRpcClient` и `AppConstants`. После этой фазы проект компилируется, `flutter analyze` чист, и можно выполнить первый RPC-вызов к локальной ноде.

---

## Components

### `pubspec.yaml` (modified)

**Current state:** только `flutter` SDK + `flutter_lints`, `flutter_test`. Строка 9–19.

**Changes:**
- Добавить 9 runtime зависимостей (алфавитный порядок, точные версии)
- Добавить 3 dev зависимости (build_runner, freezed, json_serializable)

**Resulting code:**

```yaml
dependencies:
  coinlib: 2.2.0
  flutter:
    sdk: flutter
  flutter_bloc: 8.1.6
  flutter_secure_storage: 9.2.4
  freezed_annotation: 2.4.4
  go_router: 14.8.1
  json_annotation: 4.9.0
  qr_flutter: 4.1.0
  shared_preferences: 2.3.4
  uuid: 4.5.1

dev_dependencies:
  build_runner: 2.4.13
  flutter_lints: ^6.0.0
  flutter_test:
    sdk: flutter
  freezed: 2.5.7
  json_serializable: 6.9.4
```

---

### Структура папок `lib/` (created)

**Current state:** только `lib/main.dart`.

**Changes:** создать пустые директории (`.gitkeep` не нужен — файлы появятся в следующих фазах):

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

Dart не поддерживает пустые папки в git — создаём первые файлы в Phase 2+. Структура создаётся вместе с первыми файлами каждой директории.

---

### `lib/core/constants/app_constants.dart` (created)

**Current state:** файл не существует.

**Resulting code:**

```dart
abstract final class AppConstants {
  static const String rpcUrl = 'http://127.0.0.1:18443';
  static const String rpcUser = 'bitcoin';
  static const String rpcPassword = 'bitcoin';
}
```

---

### `lib/data/api/bitcoin_rpc_client.dart` (created)

**Current state:** файл не существует.

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
// Единственный публичный метод клиента
Future<Map<String, dynamic>> BitcoinRpcClient.call(
  String method, [
  List<dynamic> params = const [],
]);

// Исключение при ошибке RPC
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
| Точные версии зависимостей | grep `^` в pubspec.yaml — не должно быть у новых пакетов |
| Нет `print` | `flutter analyze` поймает, или grep |
| Нет `!` оператора | code review |

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Конфликт версий coinlib с другими пакетами | Low | High | Версии взяты из vision — проверены заранее |
| `http` пакет не доступен без явного добавления | Low | Medium | `flutter` SDK включает `http` транзитивно; если нет — добавить явно |
| Bitcoin Core нода не запущена при тесте RPC | Medium | Low | Запустить `make btc-up && make btc-wallet-ready` перед тестом |

---

## Implementation Steps

1. Обновить `pubspec.yaml` — добавить зависимости
2. Выполнить `flutter pub get`
3. Создать `lib/core/constants/app_constants.dart`
4. Создать `lib/data/api/bitcoin_rpc_client.dart`
5. Запустить `flutter analyze` — убедиться в отсутствии предупреждений
6. Форматировать: `dart format lib/`
7. Проверить RPC вручную (нода должна быть запущена: `make btc-up`)

---

## Open Questions

None.
