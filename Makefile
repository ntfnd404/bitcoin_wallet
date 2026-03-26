# --- Infrastructure ---

# Versioned upstream Bitcoin Core base image — single source of truth.
# Update this to upgrade the node. The project image tag tracks this version.
BITCOIN_CORE_VERSION ?= 24.0.1
# Tag is kept for human readability; digest pins the exact immutable manifest.
BITCOIN_BASE_IMAGE ?= ruimarinho/bitcoin-core:$(BITCOIN_CORE_VERSION)@sha256:84bc9bb6d466d6b7eb7edaf3c35fca15b454ee0b9bf24b71593f37d3c41a4355

# Thin project image built on top of the upstream base.
BITCOIN_DOCKERFILE ?= docker/Dockerfile
BITCOIN_IMAGE      ?= bitcoin-wallet-regtest:$(BITCOIN_CORE_VERSION)

# Container name, persisted volume, and in-image config path.
BITCOIN_CONTAINER              ?= bitcoin-wallet-regtest
BITCOIN_VOLUME                 ?= bitcoin-wallet-regtest-data
BITCOIN_CONF_PATH_IN_CONTAINER ?= /etc/bitcoin/bitcoin.conf

# Ports published to localhost for RPC and P2P access.
BITCOIN_RPC_PORT ?= 18443
BITCOIN_P2P_PORT ?= 18444

# --- Demo configuration ---

# RPC credentials (regtest only — never use in production).
BITCOIN_RPC_USER     ?= bitcoin
BITCOIN_RPC_PASSWORD ?= bitcoin

# Wallet name and default address type.
BITCOIN_WALLET ?= demo
ADDRESS_TYPE   ?= bech32

# Default values for parametric targets.
ARGS    ?= getblockchaininfo
ADDRESS ?=
AMOUNT  ?= 1
TXID    ?=
VOUT    ?= 0

DOCKER             = docker
BITCOIN_NODE_CLI   = $(DOCKER) exec $(BITCOIN_CONTAINER) bitcoin-cli -conf=$(BITCOIN_CONF_PATH_IN_CONTAINER) -regtest
BITCOIN_WALLET_CLI = $(BITCOIN_NODE_CLI) -rpcwallet=$(BITCOIN_WALLET)

.PHONY: help btc-build btc-up btc-down btc-reset-data btc-restart btc-logs btc-cli btc-shell btc-status btc-blockcount btc-network-info btc-wallets btc-wallet-info btc-wallet-create btc-wallet-load btc-wallet-ready btc-balances btc-balance btc-address btc-address-legacy btc-address-p2sh-segwit btc-address-bech32 btc-address-taproot btc-mine btc-send btc-transactions btc-transaction btc-raw-transaction btc-mempool btc-utxos btc-utxo btc-docker-state btc-clean-runtime btc-clean-all

.DEFAULT_GOAL := help


# ============================================
# Help
# ============================================
# Print the available commands grouped by purpose.
help:
	@echo "╔═══════════════════════════════════════════════════════════════════════╗"
	@echo "║ Project: Bitcoin Core Demo                                            ║"
	@echo "╠═══════════════════════════════════════════════════════════════════════╣"
	@echo "║ Node lifecycle:                                                       ║"
	@echo "║   make btc-build               - Build thin project image             ║"
	@echo "║   make btc-up                  - Start regtest node in Docker         ║"
	@echo "║   make btc-down                - Stop and remove the container        ║"
	@echo "║   make btc-reset-data          - Remove persisted regtest data        ║"
	@echo "║   make btc-restart             - Recreate the regtest container       ║"
	@echo "║   make btc-logs                - Follow node logs                     ║"
	@echo "║   make btc-shell               - Open shell inside the container      ║"
	@echo "║   make btc-status              - Show regtest chain status            ║"
	@echo "║   make btc-blockcount          - Show current block height            ║"
	@echo "║   make btc-network-info        - Show network RPC info                ║"
	@echo "║   make btc-wallets             - List loaded wallets                  ║"
	@echo "║   make btc-cli                 - Run bitcoin-cli with ARGS=...        ║"
	@echo "║   make btc-docker-state        - Show project Docker artifacts        ║"
	@echo "║   make btc-clean-runtime       - Remove container and data            ║"
	@echo "║   make btc-clean-all           - Remove container, data, and images   ║"
	@echo "╠═══════════════════════════════════════════════════════════════════════║"
	@echo "║ Wallet operations:                                                    ║"
	@echo "║   make btc-wallet-create       - Create the demo wallet               ║"
	@echo "║   make btc-wallet-load         - Load the demo wallet                 ║"
	@echo "║   make btc-wallet-ready        - Load or create the wallet            ║"
	@echo "║   make btc-wallet-info         - Show wallet RPC info                 ║"
	@echo "║   make btc-balances            - Show confirmed balances              ║"
	@echo "║   make btc-balance             - Show wallet balance                  ║"
	@echo "║   make btc-address             - Create address by ADDRESS_TYPE       ║"
	@echo "║   make btc-address-legacy      - Create legacy address                ║"
	@echo "║   make btc-address-p2sh-segwit - Create wrapped segwit                ║"
	@echo "║   make btc-address-bech32      - Create native segwit address         ║"
	@echo "║   make btc-address-taproot     - Create taproot address               ║"
	@echo "║   make btc-send                - Send AMOUNT to ADDRESS               ║"
	@echo "║   make btc-mine                - Mine 101 blocks to an address        ║"
	@echo "╠═══════════════════════════════════════════════════════════════════════╣"
	@echo "║ Transaction operations:                                               ║"
	@echo "║   make btc-transactions        - List wallet transactions             ║"
	@echo "║   make btc-transaction         - Show wallet transaction by TXID      ║"
	@echo "║   make btc-raw-transaction     - Decode chain tx by TXID              ║"
	@echo "║   make btc-mempool             - Show current mempool                 ║"
	@echo "╠═══════════════════════════════════════════════════════════════════════╣"
	@echo "║ UTXO operations:                                                      ║"
	@echo "║   make btc-utxos               - List wallet UTXOs                    ║"
	@echo "║   make btc-utxo                - Show UTXO by TXID and VOUT           ║"
	@echo "╠═══════════════════════════════════════════════════════════════════════╣"
	@echo "║ Cleanup levels:                                                       ║"
	@echo "║   btc-reset-data               - Delete only persisted regtest data   ║"
	@echo "║   btc-clean-runtime            - Delete container/data, keep image    ║"
	@echo "║   btc-clean-all                - Delete container, data, and image    ║"
	@echo "╠═══════════════════════════════════════════════════════════════════════╣"
	@echo "║ Options:                                                              ║"
	@echo "║   BITCOIN_IMAGE=<tag>          - Project image tag                    ║"
	@echo "║   BITCOIN_WALLET=demo          - Wallet for RPC calls                 ║"
	@echo "║   ADDRESS_TYPE=bech32          - Address type for getnewaddress       ║"
	@echo "╚═══════════════════════════════════════════════════════════════════════╝"


# ============================================
# Node lifecycle
# ============================================
# Build the thin project image on top of the versioned upstream Bitcoin Core base.
btc-build:
	@echo " ╠ Building Bitcoin Core project image..."
	@$(DOCKER) build \
		-f $(BITCOIN_DOCKERFILE) \
		--build-arg BITCOIN_BASE_IMAGE=$(BITCOIN_BASE_IMAGE) \
		--build-arg BUILD_DATE=$(shell date -u +%Y-%m-%dT%H:%M:%SZ) \
		--build-arg GIT_REVISION=$(shell git rev-parse --short HEAD 2>/dev/null || echo unknown) \
		-t $(BITCOIN_IMAGE) \
		.
	@echo " ╚ Image ready."

# Start the node from the project image with a named Docker volume for chain
# state. Config is baked into the image and not mounted at runtime.
# Builds the image automatically only on first run; use btc-build to force a rebuild.
btc-up:
	@$(DOCKER) image inspect $(BITCOIN_IMAGE) >/dev/null 2>&1 || $(MAKE) --no-print-directory btc-build
	@echo " ╠ Starting regtest node..."
	@$(DOCKER) rm -f $(BITCOIN_CONTAINER) >/dev/null 2>&1 || true
	@$(DOCKER) run -d \
		--name $(BITCOIN_CONTAINER) \
		-p 127.0.0.1:$(BITCOIN_RPC_PORT):18443 \
		-p 127.0.0.1:$(BITCOIN_P2P_PORT):18444 \
		-v $(BITCOIN_VOLUME):/home/bitcoin/.bitcoin \
		$(BITCOIN_IMAGE)
	@echo " ╚ Regtest node started."

# Stop and remove the current regtest container.
btc-down:
	@echo " ╠ Stopping regtest node..."
	@$(DOCKER) rm -f $(BITCOIN_CONTAINER) >/dev/null 2>&1 || true
	@echo " ╚ Container removed."

# Stop the container and remove the persisted local regtest data volume.
btc-reset-data: btc-down
	@echo " ╠ Removing local regtest data volume..."
	@$(DOCKER) volume rm $(BITCOIN_VOLUME) >/dev/null 2>&1 || true
	@echo " ╚ Local regtest data removed."

# Recreate the container while keeping the persisted regtest data directory.
btc-restart: btc-down btc-up

# Follow the current node logs from the running container.
btc-logs:
	@$(DOCKER) logs -f $(BITCOIN_CONTAINER)

# Show only Docker artifacts that belong to this Bitcoin project.
btc-docker-state:
	@echo "=== Containers ==="
	@$(DOCKER) ps -a --format '{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}' | grep '$(BITCOIN_CONTAINER)' || true
	@echo "=== Images ==="
	@$(DOCKER) images --format '{{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}' | grep -E "^($(BITCOIN_IMAGE)|$(BITCOIN_BASE_IMAGE))" || true
	@echo "=== Volumes ==="
	@$(DOCKER) volume ls --format '{{.Name}}' | grep '^$(BITCOIN_VOLUME)$$' || true

# Remove project containers and local regtest data volume, but keep images.
btc-clean-runtime:
	@echo " ╠ Removing project containers..."
	@$(DOCKER) rm -f bitcoin-wallet-regtest bitcoin-wallet-bitcoin bitcoin-regtest >/dev/null 2>&1 || true
	@echo " ╠ Removing local regtest data volume..."
	@$(DOCKER) volume rm $(BITCOIN_VOLUME) >/dev/null 2>&1 || true
	@echo " ╚ Project runtime cleaned."

# Remove project containers, local regtest data, the project image, and the
# versioned upstream base image cache.
btc-clean-all: btc-clean-runtime
	@echo " ╠ Removing Bitcoin Core project image..."
	@$(DOCKER) rmi -f $(BITCOIN_IMAGE) >/dev/null 2>&1 || true
	@echo " ╠ Removing Bitcoin Core base image cache..."
	@$(DOCKER) rmi -f $(BITCOIN_BASE_IMAGE) >/dev/null 2>&1 || true
	@echo " ╚ Cold-start cleanup complete."

# Run any RPC command against the local regtest node.
# Example: `make btc-cli ARGS="getbalance"`.
btc-cli:
	@$(BITCOIN_NODE_CLI) $(ARGS)

# Show the current chain tip, blocks count and sync state.
btc-status:
	@$(BITCOIN_NODE_CLI) getblockchaininfo

# Show the current chain height.
btc-blockcount:
	@$(BITCOIN_NODE_CLI) getblockcount

# Show node network and peer-to-peer information.
btc-network-info:
	@$(BITCOIN_NODE_CLI) getnetworkinfo

# List wallets currently loaded in the node.
btc-wallets:
	@$(BITCOIN_NODE_CLI) listwallets

# Open a shell inside the running Bitcoin Core container.
btc-shell:
	@$(DOCKER) exec -it $(BITCOIN_CONTAINER) sh


# ============================================
# Wallet operations
# ============================================
# Create a named wallet for demo operations.
btc-wallet-create:
	@$(BITCOIN_NODE_CLI) createwallet "$(BITCOIN_WALLET)"

# Load an existing wallet after container restart.
btc-wallet-load:
	@$(BITCOIN_NODE_CLI) loadwallet "$(BITCOIN_WALLET)"

# Load the wallet if it exists, otherwise create it.
btc-wallet-ready:
	@if $(BITCOIN_WALLET_CLI) getwalletinfo >/dev/null 2>&1; then \
		true; \
	elif $(BITCOIN_NODE_CLI) listwalletdir | grep -F '"$(BITCOIN_WALLET)"' >/dev/null 2>&1; then \
		$(BITCOIN_NODE_CLI) loadwallet "$(BITCOIN_WALLET)" >/dev/null 2>&1; \
	else \
		$(BITCOIN_NODE_CLI) createwallet "$(BITCOIN_WALLET)"; \
	fi

# Show detailed RPC information about the selected wallet.
btc-wallet-info: btc-wallet-ready
	@$(BITCOIN_WALLET_CLI) getwalletinfo

# Show confirmed, unconfirmed, and immature balances.
btc-balances: btc-wallet-ready
	@$(BITCOIN_WALLET_CLI) getbalances

# Create a fresh regtest address for receives or mining rewards.
# Supported values: legacy, p2sh-segwit, bech32, bech32m.
btc-address: btc-wallet-ready
	@$(BITCOIN_WALLET_CLI) getnewaddress "" "$(ADDRESS_TYPE)"

# Create a legacy P2PKH address.
btc-address-legacy:
	@$(MAKE) btc-address ADDRESS_TYPE=legacy

# Create a wrapped segwit P2SH-SegWit address.
btc-address-p2sh-segwit:
	@$(MAKE) btc-address ADDRESS_TYPE=p2sh-segwit

# Create a native segwit bech32 address.
btc-address-bech32:
	@$(MAKE) btc-address ADDRESS_TYPE=bech32

# Create a taproot address via the bech32m address type.
btc-address-taproot:
	@$(MAKE) btc-address ADDRESS_TYPE=bech32m

# Show the current wallet balance.
btc-balance: btc-wallet-ready
	@$(BITCOIN_WALLET_CLI) getbalance

# Send coins from the demo wallet to the provided address.
# Example: `make btc-send ADDRESS=bcrt1... AMOUNT=0.5`.
btc-send: btc-wallet-ready
	@if [ -z "$(ADDRESS)" ]; then echo "ADDRESS is required"; exit 1; fi
	@$(BITCOIN_WALLET_CLI) sendtoaddress "$(ADDRESS)" "$(AMOUNT)"

# Mine 101 blocks so the first coinbase output becomes spendable.
btc-mine: btc-wallet-ready
	@set -e; \
		addr=$$($(BITCOIN_WALLET_CLI) getnewaddress); \
		$(BITCOIN_NODE_CLI) generatetoaddress 101 "$$addr"


# ============================================
# Transaction operations
# ============================================
# List recent wallet transactions.
btc-transactions: btc-wallet-ready
	@$(BITCOIN_WALLET_CLI) listtransactions "*" 100 0 true

# Show a wallet transaction by TXID.
# Example: `make btc-transaction TXID=<txid>`.
btc-transaction: btc-wallet-ready
	@if [ -z "$(TXID)" ]; then echo "TXID is required"; exit 1; fi
	@$(BITCOIN_WALLET_CLI) gettransaction "$(TXID)"

# Decode a transaction from the active chain or mempool by TXID.
# Example: `make btc-raw-transaction TXID=<txid>`.
btc-raw-transaction:
	@if [ -z "$(TXID)" ]; then echo "TXID is required"; exit 1; fi
	@$(BITCOIN_NODE_CLI) getrawtransaction "$(TXID)" true

# Show all transactions currently sitting in the mempool.
btc-mempool:
	@$(BITCOIN_NODE_CLI) getrawmempool true


# ============================================
# UTXO operations
# ============================================
# List spendable and locked UTXOs known to the selected wallet.
btc-utxos: btc-wallet-ready
	@$(BITCOIN_WALLET_CLI) listunspent

# Inspect a single UTXO from the current chain state.
# Example: `make btc-utxo TXID=<txid> VOUT=0`.
btc-utxo:
	@if [ -z "$(TXID)" ]; then echo "TXID is required"; exit 1; fi
	@$(BITCOIN_NODE_CLI) gettxout "$(TXID)" "$(VOUT)"
