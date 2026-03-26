# RPC Reference

All Bitcoin Core RPC calls used in this project, with key output fields to observe.

## Node state

| Make target | RPC call | Key fields to observe |
|---|---|---|
| `btc-status` | `getblockchaininfo` | `chain`, `blocks`, `headers`, `verificationprogress`, `initialblockdownload` |
| `btc-blockcount` | `getblockcount` | block height (integer) |
| `btc-network-info` | `getnetworkinfo` | `version`, `subversion`, `connections`, `localaddresses` |

## Wallet state

| Make target | RPC call | Key fields to observe |
|---|---|---|
| `btc-wallets` | `listwallets` | array of loaded wallet names |
| `btc-wallet-info` | `getwalletinfo` | `walletname`, `balance`, `txcount`, `keypoolsize` |
| `btc-balance` | `getbalance` | confirmed spendable balance (BTC) |
| `btc-balances` | `getbalances` | `mine.trusted`, `mine.untrusted_pending`, `mine.immature` |

## Addresses

| Make target | RPC call | Address type | Script |
|---|---|---|---|
| `btc-address-legacy` | `getnewaddress "" legacy` | `1...` (mainnet) / `m...` or `n...` (regtest) | P2PKH |
| `btc-address-p2sh-segwit` | `getnewaddress "" p2sh-segwit` | `3...` / `2...` (regtest) | P2SH-P2WPKH |
| `btc-address-bech32` | `getnewaddress "" bech32` | `bc1q...` / `bcrt1q...` | P2WPKH |
| `btc-address-taproot` | `getnewaddress "" bech32m` | `bc1p...` / `bcrt1p...` | P2TR |

## Mining and sending

| Make target | RPC call | Key output |
|---|---|---|
| `btc-mine` | `generatetoaddress 101 <addr>` | array of 101 block hashes |
| `btc-send` | `sendtoaddress <addr> <amount>` | TXID of created transaction |

## Transactions

| Make target | RPC call | Key fields |
|---|---|---|
| `btc-transactions` | `listtransactions * 100 0 true` | `txid`, `category` (send/receive), `amount`, `confirmations`, `time` |
| `btc-transaction` | `gettransaction <txid>` | `amount`, `fee`, `confirmations`, `blockhash`, `details`, `hex` |
| `btc-raw-transaction` | `getrawtransaction <txid> true` | `vin` (inputs), `vout` (outputs), `size`, `vsize`, `weight` |
| `btc-mempool` | `getrawmempool true` | per-TXID: `size`, `fee`, `time`, `depends` |

## UTXOs

| Make target | RPC call | Key fields |
|---|---|---|
| `btc-utxos` | `listunspent` | `txid`, `vout`, `address`, `amount`, `confirmations`, `scriptPubKey` |
| `btc-utxo` | `gettxout <txid> <vout>` | `bestblock`, `confirmations`, `value`, `scriptPubKey`, `coinbase` |

## Wallet lifecycle

| Make target | RPC call | When used |
|---|---|---|
| `btc-wallet-create` | `createwallet "demo"` | First time — wallet doesn't exist on disk |
| `btc-wallet-load` | `loadwallet "demo"` | After container restart — wallet exists but not loaded |
| `btc-wallet-ready` | auto-detects | Either of the above, picked automatically |
