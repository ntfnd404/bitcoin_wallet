# BW-0001-1: Foundation

Status: `PRD_READY`
Ticket: BW-0001
Phase: 1 of 7

---

## Context / Idea

BW-0001 строит Flutter-кошелёк с двумя типами кошельков: Node Wallet (RPC к Bitcoin Core) и HD Wallet (BIP39/32/84/86, ключи в устройстве). Phase 1 закладывает техническую основу: зависимости, структуру кода и базовый инструмент связи с нодой.

Reference: `docs/BW-0001/idea-BW-0001.md`

---

## Goals

1. Подключить все пакеты, необходимые для реализации BW-0001 (coinlib, flutter_bloc, freezed, go_router и др.)
2. Создать файловую структуру проекта согласно Clean Architecture из `docs/project/conventions.md`
3. Реализовать `BitcoinRpcClient` — единственную точку связи Flutter-приложения с Bitcoin Core

---

## User Stories

**As a developer**, I need all packages installed and the folder structure created so that I can start implementing domain models and repositories in Phase 2 without setup overhead.

**As a developer**, I need a working `BitcoinRpcClient` so that I can call any Bitcoin Core RPC method from Dart code with a single line.

---

## Main Scenarios

### Scenario 1: Добавление зависимостей — успех

- Разработчик добавляет пакеты в `pubspec.yaml` (точные версии, алфавитный порядок)
- Выполняет `flutter pub get`
- Ожидаемый результат: команда завершается успехом, `.dart_tool/package_config.json` обновлён, пакеты доступны для импорта

### Scenario 2: RPC-вызов к запущенной ноде

- Bitcoin Core нода запущена (`make btc-up && make btc-wallet-ready`)
- Код вызывает `BitcoinRpcClient().call('getblockchaininfo')`
- Ожидаемый результат: возвращается `Map` с полем `chain == 'regtest'`

### Scenario 3: RPC-вызов с ошибкой ноды

- Bitcoin Core возвращает `{"error": {"code": -32601, "message": "Method not found"}}`
- Ожидаемый результат: выбрасывается `RpcException` с полем `method` и `error`; исключение не содержит credentials в сообщении

### Scenario 4: Нода недоступна

- `http.Client` не может подключиться (нода не запущена)
- Ожидаемый результат: `SocketException` или `ClientException` пробрасывается вызывающему коду (не заглушается внутри клиента)

---

## Success / Metrics

| Criterion | Verification |
|-----------|--------------|
| `flutter pub get` завершается без ошибок | Вывод команды в терминале |
| Все 9 runtime пакетов присутствуют в pubspec.yaml | Ручная проверка файла |
| Точные версии (без `^`) у новых пакетов | grep `^` по новым строкам |
| Алфавитный порядок зависимостей | Ручная проверка |
| `lib/` структура соответствует vision-BW-0001.md | Сравнение с `docs/BW-0001/vision-BW-0001.md` |
| `BitcoinRpcClient.call('getblockchaininfo')` → `chain: regtest` | Запуск ноды + вызов |
| `flutter analyze` — ноль предупреждений | `flutter analyze --fatal-warnings` |
| Нет `print` в новых файлах | `flutter analyze` / grep |
| Нет `!` оператора в новых файлах | Code review |
| Credentials не захардкожены вне AppConstants | Code review |

---

## Constraints and Assumptions

- Версии пакетов взяты из `docs/BW-0001/vision-BW-0001.md` — не менять без обновления ADR
- `flutter_lints` остаётся с `^6.0.0` (dev tool, строгая версия не нужна)
- `flutter_test` остаётся привязан к Flutter SDK
- RPC endpoint — только regtest (`127.0.0.1:18443`), mainnet/testnet запрещены
- Нет `http` пакета в явных зависимостях — используется транзитивно через Flutter SDK

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| coinlib требует нативной компиляции (ffi) и ломается на некоторых платформах | Low | High | Проверить на macOS + iOS simulator после `pub get` |
| Версия coinlib 2.2.0 несовместима с Dart SDK ^3.11.3 | Low | High | Версия подтверждена в vision; если ломается — проверить pub.dev |

---

## Resolved Questions

- **Какую библиотеку использовать для HD деривации?** → `coinlib 2.2.0`. Единственная активная библиотека с поддержкой BIP32 + всех типов адресов + regtest + всех платформ. Решение зафиксировано в `docs/adr/ADR-001-coinlib.md`.

---

## Open Questions

None.
