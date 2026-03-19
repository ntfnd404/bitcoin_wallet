# --- Variables ---
# Upstream Bitcoin Core image tag.
BITCOIN_CORE_TAG ?= latest

# Local Docker image built by this project.
DOCKERFILE ?= docker/Dockerfile
BITCOIN_IMAGE ?= bitcoin-wallet-bitcoin-core

# Container name used by `docker run` and `docker exec`.
BITCOIN_CONTAINER ?= bitcoin-wallet-bitcoin

# Local config and blockchain storage paths.
BITCOIN_CONF ?= $(CURDIR)/docker/bitcoin.conf
BITCOIN_DATA_DIR ?= $(CURDIR)/.docker/bitcoin
BITCOIN_DATA_PATH_IN_CONTAINER ?= /bitcoin-data

# Ports published to localhost for RPC and P2P access.
BITCOIN_RPC_PORT ?= 18443
BITCOIN_P2P_PORT ?= 18444

# Demo RPC credentials used by `bitcoin-cli`.
BITCOIN_RPC_USER ?= bitcoin
BITCOIN_RPC_PASSWORD ?= bitcoin

# Wallet name used for balance, address and UTXO commands.
BITCOIN_WALLET ?= demo
ADDRESS_TYPE ?= bech32

# Default RPC command for `make bitcoin-cli`.
ARGS ?= getblockchaininfo
ADDRESS ?=
AMOUNT ?= 1
TXID ?=
VOUT ?= 0

DOCKER ?= docker
BITCOIN_NODE_CLI = $(DOCKER) exec $(BITCOIN_CONTAINER) bitcoin-cli -regtest -rpcuser=$(BITCOIN_RPC_USER) -rpcpassword=$(BITCOIN_RPC_PASSWORD)
BITCOIN_WALLET_CLI = $(BITCOIN_NODE_CLI) -rpcwallet=$(BITCOIN_WALLET)

.PHONY: help bitcoin-build bitcoin-up bitcoin-down bitcoin-reset-data bitcoin-restart bitcoin-logs bitcoin-cli bitcoin-shell bitcoin-status bitcoin-blockcount bitcoin-network-info bitcoin-wallets bitcoin-wallet-info bitcoin-wallet-create bitcoin-wallet-load bitcoin-wallet-ready bitcoin-balances bitcoin-balance bitcoin-address bitcoin-address-legacy bitcoin-address-p2sh-segwit bitcoin-address-bech32 bitcoin-address-taproot bitcoin-mine bitcoin-send bitcoin-transactions bitcoin-transaction bitcoin-raw-transaction bitcoin-mempool bitcoin-utxos bitcoin-utxo

.DEFAULT_GOAL := help


# ============================================
# Help
# ============================================
# Print the available commands grouped by purpose.
help:
	@echo "╔════════════════════════════════════════════════════════════════╗"
	@echo "║ Project: Bitcoin Core Demo                                     ║"
	@echo "╠════════════════════════════════════════════════════════════════╣"
	@echo "║ Node lifecycle:                                                ║"
	@echo "║   make bitcoin-build         - Build local Bitcoin Core image  ║"
	@echo "║   make bitcoin-up            - Start regtest node in Docker    ║"
	@echo "║   make bitcoin-down          - Stop and remove the container   ║"
	@echo "║   make bitcoin-reset-data    - Remove local regtest data       ║"
	@echo "║   make bitcoin-restart       - Recreate the regtest container  ║"
	@echo "║   make bitcoin-logs          - Follow node logs                ║"
	@echo "║   make bitcoin-shell         - Open shell inside the container ║"
	@echo "║   make bitcoin-status        - Show regtest chain status       ║"
	@echo "║   make bitcoin-blockcount    - Show current block height       ║"
	@echo "║   make bitcoin-network-info  - Show network RPC info           ║"
	@echo "║   make bitcoin-wallets       - List loaded wallets             ║"
	@echo "║   make bitcoin-cli           - Run bitcoin-cli with ARGS=...   ║"
	@echo "╠════════════════════════════════════════════════════════════════╣"
	@echo "║ Wallet operations:                                             ║"
	@echo "║   make bitcoin-wallet-create - Create the demo wallet          ║"
	@echo "║   make bitcoin-wallet-load   - Load the demo wallet            ║"
	@echo "║   make bitcoin-wallet-ready  - Load or create the wallet       ║"
	@echo "║   make bitcoin-wallet-info   - Show wallet RPC info            ║"
	@echo "║   make bitcoin-balances      - Show confirmed balances         ║"
	@echo "║   make bitcoin-balance       - Show wallet balance             ║"
	@echo "║   make bitcoin-address       - Create address by ADDRESS_TYPE  ║"
	@echo "║   make bitcoin-address-legacy - Create legacy address          ║"
	@echo "║   make bitcoin-address-p2sh-segwit - Create wrapped segwit     ║"
	@echo "║   make bitcoin-address-bech32 - Create native segwit address   ║"
	@echo "║   make bitcoin-address-taproot - Create taproot address        ║"
	@echo "║   make bitcoin-send          - Send AMOUNT to ADDRESS          ║"
	@echo "║   make bitcoin-mine          - Mine 101 blocks to an address   ║"
	@echo "╠════════════════════════════════════════════════════════════════╣"
	@echo "║ Transaction operations:                                        ║"
	@echo "║   make bitcoin-transactions - List wallet transactions         ║"
	@echo "║   make bitcoin-transaction  - Show wallet transaction by TXID  ║"
	@echo "║   make bitcoin-raw-transaction - Decode chain tx by TXID       ║"
	@echo "║   make bitcoin-mempool      - Show current mempool             ║"
	@echo "╠════════════════════════════════════════════════════════════════╣"
	@echo "║ UTXO operations:                                               ║"
	@echo "║   make bitcoin-utxos         - List wallet UTXOs               ║"
	@echo "║   make bitcoin-utxo          - Show UTXO by TXID and VOUT      ║"
	@echo "╠════════════════════════════════════════════════════════════════╣"
	@echo "║ Options:                                                       ║"
	@echo "║   BITCOIN_CORE_TAG=latest    - Upstream image tag              ║"
	@echo "║   BITCOIN_WALLET=demo        - Wallet for RPC calls            ║"
	@echo "║   ADDRESS_TYPE=bech32        - Address type for getnewaddress  ║"
	@echo "╚════════════════════════════════════════════════════════════════╝"


# ============================================
# Node lifecycle
# ============================================
# Build a local image tag on top of the upstream Bitcoin Core image.
bitcoin-build:
	@echo " ╠ Building Bitcoin Core image..."
	@$(DOCKER) build -f $(DOCKERFILE) --build-arg BITCOIN_CORE_TAG=$(BITCOIN_CORE_TAG) -t $(BITCOIN_IMAGE) .
	@echo " ╚ Image ready."

# Start the node with a mounted config and persistent regtest data directory.
# The container is recreated on each run so the command stays idempotent.
bitcoin-up: bitcoin-build
	@echo " ╠ Starting regtest node..."
	@mkdir -p $(BITCOIN_DATA_DIR)
	@$(DOCKER) rm -f $(BITCOIN_CONTAINER) >/dev/null 2>&1 || true
	@$(DOCKER) run -d \
		--name $(BITCOIN_CONTAINER) \
		-p 127.0.0.1:$(BITCOIN_RPC_PORT):18443 \
		-p 127.0.0.1:$(BITCOIN_P2P_PORT):18444 \
		-v $(BITCOIN_CONF):/home/bitcoin/.bitcoin/bitcoin.conf:ro \
		-v $(BITCOIN_DATA_DIR):$(BITCOIN_DATA_PATH_IN_CONTAINER) \
		$(BITCOIN_IMAGE) \
		-datadir=$(BITCOIN_DATA_PATH_IN_CONTAINER)
	@echo " ╚ Regtest node started."

# Stop and remove the current regtest container.
bitcoin-down:
	@echo " ╠ Stopping regtest node..."
	@$(DOCKER) rm -f $(BITCOIN_CONTAINER) >/dev/null 2>&1 || true
	@echo " ╚ Container removed."

# Stop the container and remove the persisted local regtest data directory.
bitcoin-reset-data: bitcoin-down
	@echo " ╠ Removing local regtest data..."
	@rm -rf $(BITCOIN_DATA_DIR)
	@echo " ╚ Local regtest data removed."

# Recreate the container while keeping the persisted regtest data directory.
bitcoin-restart: bitcoin-down bitcoin-up

# Follow the current node logs from the running container.
bitcoin-logs:
	@$(DOCKER) logs -f $(BITCOIN_CONTAINER)

# Run any RPC command against the local regtest node.
# Example: `make bitcoin-cli ARGS="getbalance"`.
bitcoin-cli:
	@$(BITCOIN_NODE_CLI) $(ARGS)

# Show the current chain tip, blocks count and sync state.
bitcoin-status:
	@$(BITCOIN_NODE_CLI) getblockchaininfo

# Show the current chain height.
bitcoin-blockcount:
	@$(BITCOIN_NODE_CLI) getblockcount

# Show node network and peer-to-peer information.
bitcoin-network-info:
	@$(BITCOIN_NODE_CLI) getnetworkinfo

# List wallets currently loaded in the node.
bitcoin-wallets:
	@$(BITCOIN_NODE_CLI) listwallets

# Open a shell inside the running Bitcoin Core container.
bitcoin-shell:
	@$(DOCKER) exec -it $(BITCOIN_CONTAINER) sh


# ============================================
# Wallet operations
# ============================================
# Create a named wallet for demo operations.
bitcoin-wallet-create:
	@$(BITCOIN_NODE_CLI) createwallet "$(BITCOIN_WALLET)"

# Load an existing wallet after container restart.
bitcoin-wallet-load:
	@$(BITCOIN_NODE_CLI) loadwallet "$(BITCOIN_WALLET)"

# Load the wallet if it exists, otherwise create it.
bitcoin-wallet-ready:
	@$(BITCOIN_NODE_CLI) loadwallet "$(BITCOIN_WALLET)" >/dev/null 2>&1 || \
	$(BITCOIN_NODE_CLI) createwallet "$(BITCOIN_WALLET)"

# Show detailed RPC information about the selected wallet.
bitcoin-wallet-info: bitcoin-wallet-ready
	@$(BITCOIN_WALLET_CLI) getwalletinfo

# Show confirmed, unconfirmed, and immature balances.
bitcoin-balances: bitcoin-wallet-ready
	@$(BITCOIN_WALLET_CLI) getbalances

# Create a fresh regtest address for receives or mining rewards.
# Supported values: legacy, p2sh-segwit, bech32, bech32m.
bitcoin-address: bitcoin-wallet-ready
	@$(BITCOIN_WALLET_CLI) getnewaddress "" "$(ADDRESS_TYPE)"

# Create a legacy P2PKH address.
bitcoin-address-legacy:
	@$(MAKE) bitcoin-address ADDRESS_TYPE=legacy

# Create a wrapped segwit P2SH-SegWit address.
bitcoin-address-p2sh-segwit:
	@$(MAKE) bitcoin-address ADDRESS_TYPE=p2sh-segwit

# Create a native segwit bech32 address.
bitcoin-address-bech32:
	@$(MAKE) bitcoin-address ADDRESS_TYPE=bech32

# Create a taproot address via the bech32m address type.
bitcoin-address-taproot:
	@$(MAKE) bitcoin-address ADDRESS_TYPE=bech32m

# Show the current wallet balance.
bitcoin-balance: bitcoin-wallet-ready
	@$(BITCOIN_WALLET_CLI) getbalance

# Send coins from the demo wallet to the provided address.
# Example: `make bitcoin-send ADDRESS=bcrt1... AMOUNT=0.5`.
bitcoin-send: bitcoin-wallet-ready
	@if [ -z "$(ADDRESS)" ]; then echo "ADDRESS is required"; exit 1; fi
	@$(BITCOIN_WALLET_CLI) sendtoaddress "$(ADDRESS)" "$(AMOUNT)"

# Mine 101 blocks so the first coinbase output becomes spendable.
bitcoin-mine: bitcoin-wallet-ready
	@ADDR=`$(BITCOIN_WALLET_CLI) getnewaddress`; \
	$(BITCOIN_NODE_CLI) generatetoaddress 101 $$ADDR


# ============================================
# Transaction operations
# ============================================
# List recent wallet transactions.
bitcoin-transactions: bitcoin-wallet-ready
	@$(BITCOIN_WALLET_CLI) listtransactions "*" 100 0 true

# Show a wallet transaction by TXID.
# Example: `make bitcoin-transaction TXID=<txid>`.
bitcoin-transaction: bitcoin-wallet-ready
	@if [ -z "$(TXID)" ]; then echo "TXID is required"; exit 1; fi
	@$(BITCOIN_WALLET_CLI) gettransaction "$(TXID)"

# Decode a transaction from the active chain or mempool by TXID.
# Example: `make bitcoin-raw-transaction TXID=<txid>`.
bitcoin-raw-transaction:
	@if [ -z "$(TXID)" ]; then echo "TXID is required"; exit 1; fi
	@$(BITCOIN_NODE_CLI) getrawtransaction "$(TXID)" true

# Show all transactions currently sitting in the mempool.
bitcoin-mempool:
	@$(BITCOIN_NODE_CLI) getrawmempool true


# ============================================
# UTXO operations
# ============================================
# List spendable and locked UTXOs known to the selected wallet.
bitcoin-utxos: bitcoin-wallet-ready
	@$(BITCOIN_WALLET_CLI) listunspent

# Inspect a single UTXO from the current chain state.
# Example: `make bitcoin-utxo TXID=<txid> VOUT=0`.
bitcoin-utxo:
	@if [ -z "$(TXID)" ]; then echo "TXID is required"; exit 1; fi
	@$(BITCOIN_NODE_CLI) gettxout "$(TXID)" "$(VOUT)"
