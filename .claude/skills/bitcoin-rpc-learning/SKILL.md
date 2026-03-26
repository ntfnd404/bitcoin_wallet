---
name: bitcoin-rpc-learning
description: Guided Bitcoin Core RPC practice on the local regtest node. Use when learning or teaching Bitcoin RPC concepts through this project. Follows docs/rpc-learning-path.md progression. Explains observed behaviour with make commands.
compatibility: Requires a running bitcoin-wallet-regtest node (make btc-up)
allowed-tools: Read Glob
---

# Bitcoin RPC Learning

## Sources of truth

1. `docs/learning-goals.md`
2. `docs/rpc-learning-path.md`
3. `docs/phases/progress.md`
4. `docs/app-rpc-contract.md`

For descriptions of every RPC call and its output fields, see [references/rpc-reference.md](references/rpc-reference.md).

## Rules

- Teach exclusively through `make` commands from the project `Makefile`.
- Explain behaviour from actual command output — not abstract theory.
- Keep distinctions clear: node RPC vs wallet RPC vs mempool state vs UTXO state.
- The node runs from `bitcoin-wallet-regtest:<version>` — not the upstream image.

## Teaching progression

### Foundation

```sh
make btc-up
make btc-wallet-ready
make btc-status
make btc-network-info
```

Explain: why regtest is deterministic, node vs wallet readiness, why a wallet may exist but not be loaded after restart.

### Funding and addresses

```sh
make btc-address-legacy
make btc-address-p2sh-segwit
make btc-address-bech32
make btc-address-taproot
make btc-mine
make btc-balances
```

Explain: P2PKH vs P2SH-P2WPKH vs P2WPKH vs P2TR, why 101 blocks (coinbase maturity = 100 confirmations), confirmed vs unconfirmed vs immature balance.

### Transactions and UTXOs

```sh
make btc-send ADDRESS=<address> AMOUNT=0.5
make btc-transactions
make btc-mempool
make btc-utxos
make btc-utxo TXID=<txid> VOUT=0
```

Explain: send → mempool → confirmed, UTXOs consumed (inputs) and created (outputs), `listtransactions` (wallet view) vs `getrawtransaction` (chain view).

## Output style

For each step:
1. **Command** — what to run
2. **Observe** — which fields to look at
3. **Why** — the Bitcoin Core concept behind the behaviour
