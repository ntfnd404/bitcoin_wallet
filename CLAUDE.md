# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

A Flutter wallet app paired with a local Bitcoin Core `regtest` node running in Docker. The node is for development, RPC learning, and reproducible demos — not mainnet or testnet.

## Common commands

Run `make help` for the full grouped command list. Key workflows:

```sh
# Node lifecycle
make btc-up              # Build image if needed and start node
make btc-down            # Stop and remove container
make btc-reset-data      # Wipe persisted chain data volume
make btc-restart         # Recreate container, keep chain data
make btc-logs            # Follow node stdout
make btc-shell           # Open shell in the container

# Wallet and funding
make btc-wallet-ready    # Load wallet or create it if missing
make btc-mine            # Mine 101 blocks (makes coinbase spendable)
make btc-balance         # Show wallet balance
make btc-balances        # Show confirmed/unconfirmed/immature breakdown
make btc-send ADDRESS=bcrt1... AMOUNT=0.5

# Address types
make btc-address-legacy
make btc-address-p2sh-segwit
make btc-address-bech32
make btc-address-taproot

# Transaction and UTXO inspection
make btc-transactions
make btc-transaction TXID=<txid>
make btc-raw-transaction TXID=<txid>
make btc-mempool
make btc-utxos
make btc-utxo TXID=<txid> VOUT=0

# Arbitrary RPC
make btc-cli ARGS="getblockchaininfo"

# Cleanup (in order of increasing destructiveness)
make btc-clean-runtime   # Remove container + data, keep image
make btc-clean-all       # Remove container, data, and images
```

## Architecture

### Docker layer
- `docker/Dockerfile` — thin project image on pinned upstream `ruimarinho/bitcoin-core:24.0.1`; bakes `docker/bitcoin.conf` into the image; stamped with OCI labels (build date, git revision) at build time
- `docker/bitcoin.conf` — tracked node config (`regtest`, RPC credentials `bitcoin/bitcoin`, `txindex=1`, `fallbackfee=0.0002`)
- `.dockerignore` — build context includes only `docker/bitcoin.conf`; excludes Flutter build artifacts
- Named volume `bitcoin-wallet-regtest-data` — persisted chain state; survives container recreation

### Makefile
The `Makefile` is the single source of truth for all infrastructure constants and the only supported operational interface. Key variables at the top: `BITCOIN_CORE_VERSION`, `BITCOIN_BASE_IMAGE`, `BITCOIN_IMAGE` (versioned as `bitcoin-wallet-regtest:<version>`). It defines two CLI aliases:
- `BITCOIN_NODE_CLI` — node-level RPC (no wallet context)
- `BITCOIN_WALLET_CLI` — wallet-level RPC (`-rpcwallet=demo`)

`btc-up` builds the image automatically on first run only; use `btc-build` to force a rebuild after config changes.

RPC is exposed on `127.0.0.1:18443` (RPC) and `127.0.0.1:18444` (P2P).

### Flutter app (`lib/`)
- Lives in `lib/core/` — currently early-stage
- Planned to connect to the local node via Bitcoin Core RPC HTTP calls
- App-layer models and RPC contract are tracked in `docs/app-rpc-contract.md` (Phase 04)

### Project phases
| Phase | Status | Focus |
|-------|--------|-------|
| 01 | completed | Docker + Makefile foundation |
| 02 | in progress | RPC wallet basics, address types, balances |
| 03 | planned | Send flow, transactions, mempool, UTXO tracing |
| 04 | planned | Flutter ↔ Bitcoin Core RPC integration |

## Operational rules

- Use `make` targets — do not replace them with raw `docker run` or `docker exec` unless explicitly asked.
- All infrastructure constants live in the `Makefile` variables section — there is no `constants.mk`.
- To upgrade Bitcoin Core: update `BITCOIN_CORE_VERSION` and the `sha256:` digest in `BITCOIN_BASE_IMAGE` in the `Makefile`. Get the new digest with:
  ```sh
  docker buildx imagetools inspect ruimarinho/bitcoin-core:<new-version> | grep Digest
  ```
  Use the top-level manifest list digest (first line), not a platform-specific one.
- Keep `docker/bitcoin.conf` as the tracked config source; bake it into the image via `docker/Dockerfile`.
- Do not introduce `docker-compose` for a single-service setup.
- RPC bindings stay local-first (`127.0.0.1`).

## Documentation layout

- `docs/rpc-learning-path.md` — structured learning path (Junior → Middle → Advanced)
- `docs/phases/progress.md` — current phase status and per-phase checklist
- `.claude/skills/` — skills: `/bitcoin-regtest-operator`, `/bitcoin-rpc-learning`, `/flutter-bitcoin-rpc-integration`, `/bitcoin-core-upgrade`, `/regtest-scenario`, `/prd-writing`
- Update `docs/phases/progress.md` when a phase meaningfully changes.
