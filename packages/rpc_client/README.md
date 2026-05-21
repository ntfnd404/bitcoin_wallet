# rpc_client

## Package type: Adapter (transport)

Low-level JSON-RPC transport for Bitcoin Core. Wraps HTTP + JSON-RPC envelope
parsing. No business knowledge — only wire protocol.

## Internal structure

**Flat + exceptions subfolder.** Single-concern package; no layer split needed.

```
lib/src/
  bitcoin_rpc_client.dart   ← HTTP JSON-RPC client
  exceptions/
    rpc_exception.dart      ← thrown on node error responses
```

### Why flat

This package has exactly one responsibility (HTTP transport). A layered
structure (`domain/`, `data/`) would be misleading — there is no domain here.

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
