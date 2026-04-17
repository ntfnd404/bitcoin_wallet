# Research: BW-0002 Phase 1 — Domain entities + RPC layer

Status: `RESEARCH_DONE`
Ticket: BW-0002
Phase: 1
Lane: Professional
Workflow Version: 3
Owner: Researcher

---

## Codebase Facts

- **packages/rpc_client/**: BitcoinRpcClient already exists, tested, and used by address generation and wallet creation
  - `call(method, params, walletName)` returns raw RPC result as `Object?`
  - Throws `RpcException` on RPC error
  - Supports wallet-specific endpoints via `walletName` param

- **packages/bitcoin_node/**: Adapter package with `WalletRemoteDataSourceImpl` and `AddressRemoteDataSourceImpl`
  - Pattern: ISP interfaces owned by consumer packages, adapter implements them
  - Can add `TransactionRemoteDataSourceImpl` here following the same pattern

- **packages/shared_kernel/**: Contains `BitcoinNetwork`, `AddressType`, `SecureStorage` interfaces
  - AddressType enum: legacy, wrappedSegwit, nativeSegwit, taproot — can reuse for script type mapping

- **Current architecture**: Clean layered design (domain → application → data)
  - All new packages follow: domain/ (entities, repositories, interfaces) → data/ (implementations) → public barrel API
  - Assembly pattern for DI (e.g., KeysAssembly, WalletAssembly)
  - Immutable final classes for entities

- **Existing entity patterns**:
  - `Wallet` entity in packages/wallet/lib/src/domain/entity/wallet.dart
  - `Address` entity in packages/address/lib/src/domain/entity/address.dart
  - Both use final class with const constructor, field-based equality (no custom ==)

---

## External Facts

- **Bitcoin Core RPC (regtest)**:
  - `listtransactions` method:
    - Returns array of tx objects with fields: txid, amount, confirmations, category (receive/send/generate/orphan), address, time, timereceived, comment, to, otheraccount, bip125replaceable
    - confirmations: int (0+ for confirmed, -1 for conflict, can be -block_depth for non-tip blocks)
    - Only includes wallet transactions; does NOT include mempool raw txs
  
  - `gettransaction` method:
    - Returns detailed tx object with: txid, hash, version, size, vsize, weight, locktime, vin (inputs), vout (outputs), hex (raw tx), blockhash, blockheight, blockindex, blocktime, confirmations, time, timereceived, bip125replaceable
    - vin: array of { txid, vout, scriptSig { hex, asm }, sequence }
    - vout: array of { value (BTC), n (vout index), scriptPubKey { asm, hex, type, address } }
  
  - `listunspent` method:
    - Returns array of unspent outputs: { txid, vout, address, label, scriptPubKey (hex), amount (BTC), confirmations, spendable, solvable, safe }
    - Does NOT include full input/output details; use gettxout for single output details
  
  - `gettxout` method:
    - Returns { bestblock, confirmations, value (BTC), scriptPubKey { asm, hex, type, address }, coinbase (bool) }
    - Returns null if spent
  
  - Amounts in BTC (floating point), must convert to satoshis (multiply by 1e8, handle precision)
  - scriptPubKey type field: "pubkey", "pubkeyhash", "scripthash", "multisig", "nulldata", "witness_v0_keyhash", "witness_v0_scripthash", "witness_v1_taproot", "unknown"

- **Bitcoin regtest** (running in docker):
  - Network ID: 1 (testnet3) or custom regtest ID
  - No real hashpower, blocks mined on demand via `generatetoaddress`
  - Perfect for testing tx history and UTXO state

---

## Risks

| Risk | Impact | Recommendation |
|---|---|---|
| Amount precision loss (BTC float → satoshis) | High | Use BigInt or Decimal for amounts; do not use double. Convert RPC BTC (float) to satoshis (int) with: `(amount * 1e8).toInt()` |
| scriptPubKey type mapping incomplete | Medium | Define mapping: Bitcoin Core type string → AddressType enum. Handle "unknown" gracefully. Add comment documenting mapping. |
| Confirmations = -1 (conflict) breaks UI assumptions | Low | Document in Utxo/Transaction entity that confirmations can be -1. UI can display "conflicted" state. |
| RPC field names differ between Bitcoin Core versions | Medium | Pin Bitcoin Core version in docker/bitcoin.conf with specific tag. Document RPC contract in code. |
| Empty inputs in coinbase txn crashes input parser | Low | Check inputs.isEmpty before iterating; handle gracefully in TransactionInput mapping. |
| Derivation path not available from RPC | Medium | Acknowledge in Phase 1 as limitation. Phase 2+ can compute from address if needed. For Phase 1, store null or placeholder. |

---

## Design Pressure

1. **ISP + DIP**: TransactionRemoteDataSource interface must be owned by transaction package (consumer), not bitcoin_node. Adapter implements it. This ensures high-level policy (transaction module) is not coupled to low-level details (RPC).

2. **Immutable entities**: All domain entities (Transaction, Utxo) must be immutable (final fields, const constructor). This matches existing pattern (Address, Wallet) and simplifies state management.

3. **Amount representation**: Bitcoin Core returns amounts in BTC (float). Must convert to satoshis (BigInt or int) for precision. All amounts in domain entities should be in satoshis.

4. **Assembly pattern**: New module must have TransactionAssembly and UtxoAssembly DI factories, following existing pattern (KeysAssembly, WalletAssembly). This centralizes module setup.

5. **No Flutter in domain**: Transaction module must be pure Dart (only depend on shared_kernel, wallet, address). Bitcoin Core types and RPC details stay in data/ or adapter (packages/bitcoin_node/).

---

## References

- Bitcoin Core RPC docs: https://developer.bitcoin.org/reference/rpc/ (or `make btc-help` in project)
- Existing similar module: packages/wallet/ (how Wallet, WalletRepository, WalletRemoteDataSource are structured)
- Existing adapter: packages/bitcoin_node/lib/src/wallet_remote_data_source_impl.dart
- Issue: Confirmations can be -1 for conflicted mempool txs — document in entity comments
- AddressType enum in shared_kernel — reuse for script type mapping
