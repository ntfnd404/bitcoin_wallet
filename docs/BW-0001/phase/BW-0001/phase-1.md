# Phase 1: Foundation

Status: `TASKLIST_READY`
Ticket: BW-0001
Goal: Подготовить проект к разработке — зависимости, структура папок, RPC-клиент.

Session brief — read this file only to have full context for this work session.

---

## Context

### Why this phase exists

Проект начинается с `lib/main.dart` — Hello World без архитектуры.
Перед тем как писать domain-логику, BLoC и UI, нужно:
- подключить все зависимости,
- создать файловую структуру согласно conventions,
- написать базовый RPC-клиент, который станет основой для Node Wallet.

### What this unlocks

После Phase 1 становятся возможными:
- **Phase 2** — domain models и repository interfaces (нужна структура папок)
- **Phase 3** — NodeWalletRepositoryImpl (нужен BitcoinRpcClient)
- **Phase 4** — HD Wallet (нужны coinlib и flutter_secure_storage)

### Key constraints

- Точные версии без `^` (`coinlib: 2.2.0`, не `^2.2.0`)
- Зависимости отсортированы алфавитно в pubspec.yaml
- RPC endpoint: `http://bitcoin:bitcoin@127.0.0.1:18443`
- Никогда `!` оператор и `print` в коде
- Один класс = один файл
- Функции: до 20 строк, единственная ответственность

### Technologies

| Technology | Package | Role |
|------------|---------|------|
| HTTP client | `dart:io` / `http` (flutter built-in) | JSON-RPC запросы к Bitcoin Core |
| BIP39 / HD ключи | `coinlib: 2.2.0` | Деривация адресов, все типы, regtest |
| State management | `flutter_bloc: 8.1.6` | BLoC паттерн |
| Secure storage | `flutter_secure_storage: 9.2.4` | Хранение seed phrase |
| Code generation | `freezed: 2.5.7` + `build_runner: 2.4.13` | Freezed models |
| Navigation | `go_router: 14.8.1` | Маршрутизация |
| QR коды | `qr_flutter: 4.1.0` | Отображение адресов |

---

## Tasks

### `pubspec.yaml`

- [ ] 1.1 Добавить все зависимости
  Acceptance: `flutter pub get` завершается без ошибок; все пакеты видны на всех платформах

### `lib/` структура папок

- [ ] 1.2 Создать структуру директорий
  Acceptance: структура совпадает с `docs/BW-0001/vision-BW-0001.md`

### `lib/data/api/bitcoin_rpc_client.dart`

- [ ] 1.3 Реализовать BitcoinRpcClient
  Acceptance: вызов `getblockchaininfo` возвращает `chain: regtest`

### After changes

- [ ] Run `flutter analyze` — zero warnings/infos
- [ ] Format changed files: `dart format lib/`

---

## Acceptance Criteria

- `flutter pub get` — успех, без конфликтов версий
- Структура `lib/` соответствует vision-BW-0001.md (только папки, файлы добавляются в следующих фазах)
- `BitcoinRpcClient.call('getblockchaininfo')` возвращает `{'chain': 'regtest', ...}`
- `flutter analyze` — ноль предупреждений и ошибок
- Credentials не захардкожены в коде вне `AppConstants`

---

## Dependencies

No prior phases required. Phase 1 — первая.

---

## Technical Details

### pubspec.yaml — итоговый вид dependencies

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

### BitcoinRpcClient — скелет

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

### AppConstants (набросок для Phase 1)

```dart
// lib/core/constants/app_constants.dart
abstract final class AppConstants {
  static const String rpcUrl = 'http://127.0.0.1:18443';
  static const String rpcUser = 'bitcoin';
  static const String rpcPassword = 'bitcoin';
}
```

### Gotcha: `http` пакет

`flutter` уже включает `http` через flutter SDK — не добавляем отдельно.
`BitcoinRpcClient` импортирует `package:http/http.dart`.
