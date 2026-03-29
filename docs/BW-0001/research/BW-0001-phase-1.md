# Research: BW-0001 Phase 1 — Foundation

Status: `RESEARCH_DONE`
Ticket: BW-0001

---

## Investigation

### Текущее состояние кодовой базы

- `lib/main.dart` — 20 строк, Hello World (`MaterialApp` + `Text('Hello World!')`)
- `pubspec.yaml` — только `flutter` SDK, `flutter_lints`, `flutter_test`
- Dart SDK: `^3.11.3`
- Нет структуры папок, нет зависимостей

### Зависимости — исследование

Полное исследование проведено в `docs/BW-0001/vision-BW-0001.md`, раздел "Dependencies".

Ключевые находки:
- **coinlib 2.2.0** — единственная активная Dart-библиотека с полной поддержкой BIP32 + P2PKH + P2SH-P2WPKH + P2WPKH + P2TR + regtest network params + все платформы
- **flutter_secure_storage 9.2.4** — Web использует незашифрованный `localStorage` (требует предупреждение в UI)
- `http` пакет доступен транзитивно через Flutter SDK — не добавляем явно

### RPC-клиент — исследование

Bitcoin Core RPC:
- Протокол: JSON-RPC 1.0
- Auth: HTTP Basic (`bitcoin:bitcoin`)
- Endpoint: `http://127.0.0.1:18443` (regtest)
- Успешный ответ: `{"result": {...}, "error": null, "id": "..."}`
- Ошибка: `{"result": null, "error": {"code": -N, "message": "..."}, "id": "..."}`

Параметры из `docker/bitcoin.conf` (подтверждены):
```
rpcuser=bitcoin
rpcpassword=bitcoin
rpcbind=127.0.0.1
rpcport=18443
```

---

## Key Decisions

| Decision | Rationale | Alternatives |
|----------|-----------|--------------|
| `coinlib: 2.2.0` для HD деривации | Единственная активная библиотека с полной поддержкой BIP32 + всех addr типов + regtest + все платформы | `bip39` (только мнемоника), `hdwallet` (нет Taproot), `bitcoin_flutter` (не поддерживается) |
| Точные версии без `^` | Воспроизводимые сборки; изменение версии — явное действие | Caret ranges — создают неожиданные обновления |
| `AppConstants` для credentials | Нет magic strings в коде; единственное место для изменения при переключении окружений | Env variables — излишне для regtest demo |
| `http.Client` как зависимость через конструктор | Тестируемость (можно подменить mock-клиент) | Статический метод — нельзя тестировать |

---

## Technical Details

### Итоговые версии пакетов (из vision-BW-0001.md)

```yaml
# runtime
coinlib: 2.2.0
flutter_bloc: 8.1.6
flutter_secure_storage: 9.2.4
freezed_annotation: 2.4.4
go_router: 14.8.1
json_annotation: 4.9.0
qr_flutter: 4.1.0
shared_preferences: 2.3.4
uuid: 4.5.1

# dev
build_runner: 2.4.13
freezed: 2.5.7
json_serializable: 6.9.4
```

### JSON-RPC ответ — структура

```dart
// Успех
{
  "result": {"chain": "regtest", "blocks": 101, ...},
  "error": null,
  "id": "getblockchaininfo"
}

// Ошибка
{
  "result": null,
  "error": {"code": -32601, "message": "Method not found"},
  "id": "unknownmethod"
}
```

### Структура lib/ согласно vision

```
lib/
├── core/constants/app_constants.dart        ← создаётся в Phase 1
├── data/api/bitcoin_rpc_client.dart         ← создаётся в Phase 1
├── data/repository/                         ← Phase 3, 4
├── data/service/                            ← Phase 4
├── data/storage/                            ← Phase 3
├── domain/model/                            ← Phase 2
├── domain/repository/                       ← Phase 2
├── domain/service/                          ← Phase 2
├── feature/wallet/bloc/                     ← Phase 5
├── feature/wallet/di/                       ← Phase 5
├── feature/wallet/view/                     ← Phase 6
├── routing/                                 ← Phase 7
└── view/                                    ← Phase 6
```

---

## Risks Identified

| Risk | Impact | Recommendation |
|------|--------|----------------|
| coinlib использует FFI — может потребовать дополнительных настроек на некоторых платформах | High | Проверить `flutter pub get` + `flutter build` на macOS сразу после добавления |
| flutter_secure_storage на Web — незашифрованный localStorage | Medium | Добавить UI-предупреждение в Phase 6 (AddressScreen или WalletDetailScreen) |

---

## References

- `docs/BW-0001/vision-BW-0001.md` — полное техническое описание BW-0001
- `docs/adr/ADR-001-coinlib.md` — решение по выбору библиотеки деривации
- `docker/bitcoin.conf` — RPC credentials и настройки ноды
- `docs/project/conventions.md` — архитектурные правила проекта
