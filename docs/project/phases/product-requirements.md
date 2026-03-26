# Product Requirements Document: Bitcoin Wallet (Regtest)

Status: `draft`
Last updated: 2026-03-26

---

## 1. Overview

### Problem statement

Understanding Bitcoin internals — UTXO model, transaction construction, script execution, HD key derivation — requires a safe, controllable environment where mistakes have no real cost and every step can be inspected. Public testnet introduces network dependencies and unpredictable block times. Existing wallet apps hide implementation details behind abstraction.

### Proposed solution

A Flutter application backed by a local Bitcoin Core `regtest` node that exposes the full Bitcoin programming model: key derivation from seed phrases, manual UTXO selection, custom Bitcoin Script, coin selection strategies, and transaction inspection. The app serves two purposes simultaneously: a personal learning environment and a portfolio-quality demonstration of Bitcoin engineering skills.

---

## 2. Goals and success metrics

### Goals

1. Implement all major Bitcoin wallet primitives from seed phrase to confirmed transaction.
2. Make the UTXO model visible and interactive, not hidden behind a balance number.
3. Support Bitcoin Script construction and broadcast for educational scenarios.
4. Demonstrate production-quality Flutter architecture to technical reviewers.
5. Keep the environment fully local, deterministic, and reproducible.

### Success metrics

| Metric | Target |
|---|---|
| All core flows completable end-to-end without errors | 100% of listed user stories |
| Node connectivity visible in the UI on app launch | Connection status shown within 1s |
| Transaction broadcast confirmed in next mined block | Works on every send in regtest |
| Seed phrase import produces correct addresses | Matches Bitcoin Core derivation for BIP84 |
| UTXO selection strategies produce different fee outcomes | At least 3 strategies implemented and comparable |
| Code reviewable by a senior Bitcoin or Flutter engineer | No unexplained magic; architecture documented |

---

## 3. User stories

### Primary user: the developer learning Bitcoin internals

- As a developer, I want to generate a wallet from a BIP39 seed phrase so that I understand HD key derivation (BIP32/44/84/86).
- As a developer, I want to see my UTXOs individually so that I understand why Bitcoin has no "balance" at the protocol level.
- As a developer, I want to select UTXOs manually for a transaction so that I understand coin selection and fee calculation.
- As a developer, I want to compare coin selection strategies (FIFO, LIFO, minimize inputs, minimize change) so that I can see their effect on fees and privacy.
- As a developer, I want to construct and broadcast a transaction with a custom `OP_RETURN` output so that I understand Bitcoin Script basics.
- As a developer, I want to inspect a raw transaction and decode its inputs, outputs, and script so that I understand the serialization format.
- As a developer, I want to mine a block after sending so that I can immediately see confirmation in the transaction history.

### Secondary user: technical reviewer (employer or developer evaluating the portfolio)

- As a reviewer, I want to see clean Flutter architecture (layered, testable) so that I can assess the developer's engineering approach.
- As a reviewer, I want to see the app working end-to-end in a demo so that I can verify the claims without setting up anything myself.
- As a reviewer, I want to read the code for Bitcoin-specific logic (UTXO selection, script construction) so that I can assess Bitcoin domain knowledge.

---

## 4. Requirements

### 4.1 Node connectivity

- The app must connect to a local Bitcoin Core `regtest` node via HTTP JSON-RPC.
- The app must display node connectivity status (reachable / unreachable) on every screen.
- The app must display current block height and chain name.
- RPC credentials and host are configured at build time for the local regtest setup; no runtime credential UI is required.

### 4.2 Seed phrase and key derivation

- The app must generate a BIP39 mnemonic (12 or 24 words).
- The app must derive keys following BIP84 (native SegWit, `m/84'/1'/0'`) for regtest.
- The app must display the derived `xpub`, derivation path, and first receiving address.
- The app must import an existing BIP39 mnemonic and restore the same addresses.
- The app must support at minimum: P2PKH (legacy), P2SH-P2WPKH (wrapped SegWit), P2WPKH (native SegWit), P2TR (Taproot).

### 4.3 Address management

- The app must generate a new receive address on demand for each supported address type.
- The app must display the address in both text and QR code format.
- The app must label addresses (used / unused) based on transaction history.

### 4.4 Balance and wallet state

- The app must display confirmed, unconfirmed, and immature balances separately.
- The app must refresh balances on user request and after sending a transaction.

### 4.5 UTXO management

- The app must list all unspent outputs with: TXID, vout index, amount, confirmations, address, script type.
- The app must allow the user to select UTXOs manually for a send transaction.
- The app must show which UTXOs are locked (reserved) vs available.
- The app must display UTXO details: full raw output script, script type, derivation path.

### 4.6 Coin selection strategies

The app must implement and expose at least three coin selection strategies:

| Strategy | Description |
|---|---|
| FIFO | Oldest UTXOs first |
| LIFO | Newest UTXOs first |
| Minimize inputs | Fewest UTXOs to cover amount |
| Minimize change | Closest match to amount to reduce change output |

- The app must show estimated fee, number of inputs, and change amount for each strategy before the user confirms.
- The app must allow switching between strategies on the send screen.

### 4.7 Send transaction

- The app must allow the user to enter a destination address and amount.
- The app must estimate the fee based on selected UTXOs and a target fee rate (sat/vB).
- The app must show a transaction summary (inputs, outputs, fee, change) before broadcast.
- The app must broadcast the transaction to the local node via `sendrawtransaction` or `sendtoaddress`.
- The app must display the resulting TXID after broadcast.

### 4.8 Bitcoin Script

- The app must support constructing and broadcasting a transaction with an `OP_RETURN` output carrying arbitrary data (up to 80 bytes).
- The app must display the decoded script for any input or output (locking script, unlocking script).
- The app must label script types: P2PKH, P2SH, P2WPKH, P2WSH, P2TR, OP_RETURN, UNKNOWN.

### 4.9 Transaction history and inspection

- The app must list wallet transactions with: TXID, direction (in/out), amount, confirmations, timestamp.
- The app must show transaction detail: all inputs (with previous output), all outputs (address, amount, script), fee, size in bytes, weight.
- The app must decode and display the raw hex of any transaction.
- The app must distinguish mempool (unconfirmed) transactions from confirmed ones.

### 4.10 Regtest controls

- The app must expose a "Mine block" action that calls `generatetoaddress` to confirm pending transactions.
- The number of blocks to mine is configurable (default: 1).

### 4.11 Non-functional requirements

- The app must run on iOS, Android, macOS, and web (Flutter multi-platform).
- The app must follow a layered architecture: data layer (RPC), domain layer (models, business logic), presentation layer (UI).
- All Bitcoin-specific logic (script construction, UTXO selection, key derivation) must be unit-testable in isolation.
- No mainnet or testnet keys, no real funds, no production RPC endpoints.

---

## 5. Out of scope

The following will NOT be built in this project:

- Mainnet or testnet support
- Lightning Network
- Multisig wallets
- Hardware wallet integration (Ledger, Trezor)
- Watch-only wallets
- Wallet backup and encrypted storage
- Push notifications for incoming transactions
- Fee estimation from mempool (fixed or user-set fee rate only)
- Address book / contacts
- Fiat currency conversion
- Any backend server or proxy between app and Bitcoin Core

---

## 6. Dependencies and risks

### Dependencies

| Dependency | Notes |
|---|---|
| Bitcoin Core `regtest` node | Local Docker setup via `make btc-up`; must be running for all app flows |
| Flutter SDK | Multi-platform build target |
| BIP39/32/84/86 Dart library | `bip39`, `bitcoin_flutter`, or equivalent; needs regtest network support |
| HTTP JSON-RPC client | Standard `http` package or `dio`; no special Bitcoin library needed |

### Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Dart BIP libraries don't support regtest derivation paths | Medium | Verify library against Bitcoin Core key derivation before committing to it |
| Raw transaction construction is error-prone | High | Build integration tests that broadcast to regtest and verify with `getrawtransaction` |
| UTXO selection logic diverges from Bitcoin Core behavior | Medium | Compare outputs of custom strategies with `fundrawtransaction` results |
| Reviewer unfamiliar with regtest setup | Low | README must include a one-command setup path |

### Decisions

- The app signs transactions internally with private keys held in memory. Bitcoin Core's `signrawtransactionwithwallet` is not used — self-signing is the point of the exercise.

### Open questions

- Which Dart library will be used for key derivation and transaction signing? (to be decided in Phase 06)
- Which specific Bitcoin Script scenarios beyond `OP_RETURN` are in scope? (timelock, multisig, etc.)

---

## 7. Phases and milestones

| Phase | Status | Deliverable |
|---|---|---|
| 01: Regtest foundation | `completed` | Local Docker node, Makefile, reproducible environment |
| 02: Node connectivity and wallet state | `in progress` | Flutter RPC client; node status, block height, wallet state, balances |
| 03: Address management | `planned` | Address generation (all types) with QR code display |
| 04: Transaction history and UTXO inspection | `planned` | Transaction list and detail, UTXO list and detail, mempool state |
| 05: Send transaction and coin selection | `planned` | Send flow, FIFO/LIFO/minimize strategies, manual UTXO selection, mine block |
| 06: Key derivation and self-signing | `planned` | BIP39 mnemonic, BIP84 derivation, in-app transaction signing |
| 07: Bitcoin Script | `planned` | OP_RETURN broadcast, script decoder, script type labeling |
| 08: Polish and demo | `planned` | Multi-platform builds, README demo path, architecture documentation |
