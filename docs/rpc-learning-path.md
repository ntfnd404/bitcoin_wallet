# RPC learning path

This document provides a practical route for learning Bitcoin Core RPC against the local `regtest` node.

## Junior

Learn how to inspect node state and wallet basics.

1. `make bitcoin-up`
2. `make bitcoin-wallet-ready`
3. `make bitcoin-status`
4. `make bitcoin-blockcount`
5. `make bitcoin-network-info`
6. `make bitcoin-wallet-info`
7. `make bitcoin-wallets`

## Middle

Practice funding, address types, and wallet balances.

1. `make bitcoin-address-legacy`
2. `make bitcoin-address-p2sh-segwit`
3. `make bitcoin-address-bech32`
4. `make bitcoin-address-taproot`
5. `make bitcoin-mine`
6. `make bitcoin-balance`
7. `make bitcoin-balances`
8. `make bitcoin-send ADDRESS=<bcrt-address> AMOUNT=0.5`

## Advanced

Study transaction flow, mempool state, and UTXO inspection.

1. `make bitcoin-transactions`
2. `make bitcoin-transaction TXID=<txid>`
3. `make bitcoin-raw-transaction TXID=<txid>`
4. `make bitcoin-mempool`
5. `make bitcoin-utxos`
6. `make bitcoin-utxo TXID=<txid> VOUT=0`
7. `make bitcoin-cli ARGS='listunspent 1 9999999 [] true'`
