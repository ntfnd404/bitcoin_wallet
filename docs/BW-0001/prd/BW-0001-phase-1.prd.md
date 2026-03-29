# BW-0001-1: Foundation

Status: `PRD_READY`
Ticket: BW-0001
Phase: 1 of 7

---

## Context / Idea

BW-0001 builds a Flutter wallet with two wallet types: Node Wallet (RPC to Bitcoin Core) and HD Wallet (BIP39/32/84/86, keys on device). Phase 1 lays the technical foundation: dependencies, code structure, and the basic communication tool with the node.

Reference: `docs/BW-0001/idea-BW-0001.md`

---

## Goals

1. Add all packages required for BW-0001 implementation (crypto, pointycastle, flutter_bloc, flutter_secure_storage, etc.)
2. Create the project folder structure per Clean Architecture from `docs/project/conventions.md`
3. Implement `BitcoinRpcClient` — the single point of communication between the Flutter app and Bitcoin Core

---

## User Stories

**As a developer**, I need all packages installed and the folder structure created so that I can start implementing domain models and repositories in Phase 2 without setup overhead.

**As a developer**, I need a working `BitcoinRpcClient` so that I can call any Bitcoin Core RPC method from Dart code with a single line.

---

## Main Scenarios

### Scenario 1: Adding dependencies — success

- Developer adds packages to `pubspec.yaml` (exact versions, alphabetical order)
- Runs `flutter pub get`
- Expected result: command completes successfully, `.dart_tool/package_config.json` is updated, packages are available for import

### Scenario 2: RPC call to a running node

- Bitcoin Core node is running (`make btc-up && make btc-wallet-ready`)
- Code calls `BitcoinRpcClient().call('getblockchaininfo')`
- Expected result: returns a `Map` with field `chain == 'regtest'`

### Scenario 3: RPC call with node error

- Bitcoin Core returns `{"error": {"code": -32601, "message": "Method not found"}}`
- Expected result: `RpcException` is thrown with fields `method` and `error`; the exception message does not contain credentials

### Scenario 4: Node unavailable

- `http.Client` cannot connect (node is not running)
- Expected result: `SocketException` or `ClientException` is propagated to the caller (not suppressed inside the client)

---

## Success / Metrics

| Criterion | Verification |
|-----------|--------------|
| `flutter pub get` completes without errors | Command output in terminal |
| All 6 runtime packages present in pubspec.yaml | Manual file inspection |
| Exact versions (no `^`) on new packages | grep `^` on new lines |
| Alphabetical order of dependencies | Manual inspection |
| `lib/` structure matches vision-BW-0001.md | Compare with `docs/BW-0001/vision-BW-0001.md` |
| `BitcoinRpcClient.call('getblockchaininfo')` → `chain: regtest` | Start node + call |
| `flutter analyze` — zero warnings | `flutter analyze --fatal-warnings` |
| No `print` in new files | `flutter analyze` / grep |
| No `!` operator in new files | Code review |
| Credentials not hardcoded outside AppConstants | Code review |

---

## Constraints and Assumptions

- Package versions are taken from `docs/BW-0001/vision-BW-0001.md` — do not change without updating the ADR
- `flutter_lints` stays at `^6.0.0` (dev tool, strict version not needed)
- `flutter_test` stays bound to Flutter SDK
- RPC endpoint — regtest only (`127.0.0.1:18443`), mainnet/testnet prohibited
- No `http` package in explicit dependencies — used transitively through Flutter SDK

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| pointycastle 4.0.0 — new major version, API may differ from examples | Low | Medium | Check documentation before Phase 4 |
| crypto/pointycastle version conflict with Dart SDK ^3.11.3 | Low | High | Versions confirmed in vision; if broken — check pub.dev |

---

## Resolved Questions

- **Which library to use for HD derivation?** → `crypto: 3.0.7` + `pointycastle: 4.0.0`. BIP39/BIP32/address encoding is implemented manually using low-level crypto primitives — the goal is to demonstrate knowledge of Bitcoin standards. No high-level Bitcoin wallet library is used.

---

## Open Questions

None.
