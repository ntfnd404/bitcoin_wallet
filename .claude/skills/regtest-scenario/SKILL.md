---
name: regtest-scenario
description: Set up a specific, reproducible Bitcoin regtest chain state for testing or demo. Use when you need a clean chain, a funded wallet, a pending mempool transaction, a confirmed send, or a multi-address setup. Also covers volume snapshots.
compatibility: Requires Docker and make
allowed-tools: Read Bash
---

# Regtest Scenario Runner

## Available scenarios

### 1. Clean chain

State: node running, wallet ready, zero blocks, no funds.

```sh
make btc-reset-data
make btc-up
make btc-wallet-ready
make btc-status        # confirm blocks=0
```

### 2. Funded wallet

State: 101+ blocks mined, wallet has spendable coinbase funds.

```sh
make btc-up
make btc-wallet-ready
make btc-mine          # mines 101 blocks → first coinbase is spendable
make btc-balances      # mine.trusted > 0
```

### 3. Pending mempool transaction

State: a send has been broadcast but not confirmed.

```sh
# Start from funded wallet scenario
addr=$(make btc-address-bech32 2>/dev/null | tail -1)
make btc-send ADDRESS=$addr AMOUNT=0.5
make btc-mempool       # tx appears here
make btc-balances      # mine.untrusted_pending is non-zero
```

### 4. Confirmed send — trace UTXO change

State: send is confirmed; original UTXO consumed, change UTXO created.

```sh
addr=$(make btc-address-bech32 2>/dev/null | tail -1)
txid=$(make btc-send ADDRESS=$addr AMOUNT=0.5 2>/dev/null | tail -1)
make btc-mine
make btc-transaction TXID=$txid
make btc-utxos
make btc-raw-transaction TXID=$txid   # inspect inputs and outputs
```

### 5. Multi-address demo

State: wallet has addresses of all four types.

```sh
make btc-address-legacy
make btc-address-p2sh-segwit
make btc-address-bech32
make btc-address-taproot
make btc-mine
make btc-utxos
```

## Reset between scenarios

```sh
make btc-reset-data
make btc-up
```

## Volume snapshot (preserve and restore state)

Save:
```sh
make btc-down
docker run --rm \
  -v bitcoin-wallet-regtest-data:/source \
  -v $(pwd)/.docker/snapshots:/backup \
  alpine tar czf /backup/regtest-snapshot.tar.gz -C /source .
make btc-up
```

Restore:
```sh
make btc-reset-data
docker run --rm \
  -v bitcoin-wallet-regtest-data:/target \
  -v $(pwd)/.docker/snapshots:/backup \
  alpine tar xzf /backup/regtest-snapshot.tar.gz -C /target
make btc-up
```
