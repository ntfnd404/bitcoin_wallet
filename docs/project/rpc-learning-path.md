# RPC learning path

This document provides a practical route for learning Bitcoin Core RPC against the local `regtest` node.

## Junior

Learn how to inspect node state and wallet basics.

1. `make btc-up`
2. `make btc-wallet-ready`
3. `make btc-status`
4. `make btc-blockcount`
5. `make btc-network-info`
6. `make btc-wallet-info`
7. `make btc-wallets`

## Middle

Practice funding, address types, and wallet balances.

1. `make btc-address-legacy`
2. `make btc-address-p2sh-segwit`
3. `make btc-address-bech32`
4. `make btc-address-taproot`
5. `make btc-mine`
6. `make btc-balance`
7. `make btc-balances`
8. `make btc-send ADDRESS=<bcrt-address> AMOUNT=0.5`

## Advanced

Study transaction flow, mempool state, and UTXO inspection.

1. `make btc-transactions`
2. `make btc-transaction TXID=<txid>`
3. `make btc-raw-transaction TXID=<txid>`
4. `make btc-mempool`
5. `make btc-utxos`
6. `make btc-utxo TXID=<txid> VOUT=0`
7. `make btc-cli ARGS='listunspent 1 9999999 [] true'`
