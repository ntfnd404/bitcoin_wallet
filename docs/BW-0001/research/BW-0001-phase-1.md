# Research: BW-0001 Phase 1 — Foundation

Status: `RESEARCH_DONE`
Ticket: BW-0001

---

## Investigation

### Current codebase state

- `lib/main.dart` — 20 lines, Hello World (`MaterialApp` + `Text('Hello World!')`)
- `pubspec.yaml` — only `flutter` SDK, `flutter_lints`, `flutter_test`
- Dart SDK: `^3.11.3`
- No folder structure, no dependencies

### Dependencies — research

Full investigation was conducted in `docs/BW-0001/vision-BW-0001.md`, section "Dependencies".

Key findings:
- **crypto 3.0.7** + **pointycastle 4.0.0** — low-level crypto primitives; BIP39/BIP32/addresses implemented manually (the goal is to demonstrate knowledge of Bitcoin standards)
- **flutter_secure_storage 10.0.0** — Web uses unencrypted `localStorage` (requires a warning in the UI); used for both seed phrases and wallet metadata
- `http` package is available transitively through the Flutter SDK — do not add explicitly

### RPC client — research

Bitcoin Core RPC:
- Protocol: JSON-RPC 1.0
- Auth: HTTP Basic (`bitcoin:bitcoin`)
- Endpoint: `http://127.0.0.1:18443` (regtest)
- Success response: `{"result": {...}, "error": null, "id": "..."}`
- Error response: `{"result": null, "error": {"code": -N, "message": "..."}, "id": "..."}`

Parameters from `docker/bitcoin.conf` (confirmed):
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
| `crypto: 3.0.7` + `pointycastle: 4.0.0` for HD derivation | Implement BIP39/BIP32 manually to demonstrate knowledge of standards; no high-level Bitcoin library used | coinlib — superseded; abstracts away the internals |
| Exact versions without `^` | Reproducible builds; version change is an explicit action | Caret ranges — cause unexpected updates |
| `AppConstants` for credentials | No magic strings in code; single place to change when switching environments | Env variables — overkill for regtest demo |
| `http.Client` as constructor dependency | Testability (can inject a mock client) | Static method — cannot be tested |
| Plain immutable Dart classes instead of freezed | Demonstrates OOP knowledge, no code generation magic | freezed (code generation) |
| Flutter built-in Navigator instead of go_router | Simpler, no extra dependency for demo app | go_router, auto_route |
| `flutter_secure_storage` for all storage instead of `shared_preferences` | Single storage layer for both sensitive data and wallet metadata | shared_preferences + flutter_secure_storage |

---

## Technical Details

### Final package versions (from vision-BW-0001.md)

```yaml
# runtime
crypto: 3.0.7
pointycastle: 4.0.0
flutter_bloc: 9.1.1
flutter_secure_storage: 10.0.0
json_annotation: 4.11.0
uuid: 4.5.3

# dev
json_serializable: 6.13.1
```

### JSON-RPC response — structure

```dart
// Success
{
  "result": {"chain": "regtest", "blocks": 101, ...},
  "error": null,
  "id": "getblockchaininfo"
}

// Error
{
  "result": null,
  "error": {"code": -32601, "message": "Method not found"},
  "id": "unknownmethod"
}
```

### Project structure per vision

```
lib/
├── core/constants/app_constants.dart        ← Phase 1 (exists)
├── core/routing/app_router.dart             ← Phase 7
├── common/widgets/                          ← Phase 6
├── common/extensions/                       ← as needed
├── feature/wallet/bloc/                     ← Phase 5
├── feature/wallet/di/                       ← Phase 5
└── feature/wallet/view/screen/             ← Phase 6

packages/
├── rpc/    bitcoin_rpc_client.dart          ← Phase 1 (exists)
├── storage/ secure_storage.dart            ← Phase 3
├── domain/  entity/, repository/, service/ ← Phase 2
├── data/    repository/, service/          ← Phase 3, 4
└── ui_kit/  tokens/, typography/, theme/   ← Phase 6
```

---

## Risks Identified

| Risk | Impact | Recommendation |
|------|--------|----------------|
| pointycastle 4.0.0 — new major version, API may differ from examples | Medium | Check documentation before Phase 4 |
| flutter_secure_storage on Web — unencrypted localStorage | Medium | Add UI warning in Phase 6 (AddressScreen or WalletDetailScreen) |

---

## References

- `docs/BW-0001/vision-BW-0001.md` — full technical description of BW-0001
- ADR-001-coinlib.md superseded: using crypto + pointycastle, implementing BIP39/BIP32 manually
- `docker/bitcoin.conf` — RPC credentials and node settings
- `docs/project/conventions.md` — project architecture rules
