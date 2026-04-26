# rpc_client

## Purpose

Low-level JSON-RPC transport for Bitcoin Core. The package sends HTTP requests
to a Bitcoin Core node and deserialises the JSON-RPC envelope. It has no
knowledge of domain entities; it only wraps the wire protocol.

## Public API

Barrel: `package:rpc_client/rpc_client.dart`

| Symbol | Kind | Description |
|---|---|---|
| `BitcoinRpcClient` | class | Sends JSON-RPC calls to a Bitcoin Core endpoint |
| `RpcException` | class | Thrown when Bitcoin Core returns an error response |

## Dependencies

Workspace packages: none (leaf).
Third-party: `http: 1.6.0`.
SDK: Dart SDK only.

## When to add here

Add a symbol only when it is a direct concern of the JSON-RPC transport layer:
raw request/response types, the HTTP client wrapper, exception types for
transport and protocol errors. Never add domain entities, repositories, or
business logic.

## Layer layout

```
lib/
  rpc_client.dart             # barrel
  src/
    bitcoin_rpc_client.dart
    exceptions/
      rpc_exception.dart
```
