# Regtest Diagnostics

Common failure patterns and how to diagnose them.

## Node fails to start (`make btc-up`)

| Symptom | Likely cause | Check |
|---------|-------------|-------|
| `docker: command not found` | Docker not installed / not in PATH | `docker --version` |
| `Cannot connect to the Docker daemon` | Docker daemon not running | Start Docker Desktop |
| `port is already allocated` | Port 18443 or 18444 in use | `lsof -i :18443` |
| `No such image` | Project image not built | `make btc-build` |
| Image built but old config | bitcoin.conf changed after last build | `make btc-build && make btc-restart` |

## RPC unreachable (`make btc-status` hangs or errors)

| Symptom | Likely cause | Check |
|---------|-------------|-------|
| `Connection refused` | Node not running | `docker ps | grep bitcoin-wallet-regtest` |
| `Authorization failed` | Wrong RPC credentials | Check `BITCOIN_RPC_USER`/`BITCOIN_RPC_PASSWORD` in Makefile |
| `Loading block index...` | Node still starting | Wait 10–20s, check `make btc-logs` |
| HEALTHCHECK failing | bitcoind crashed | `make btc-logs` for crash reason |

## Wallet issues

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `Requested wallet does not exist` | Wallet not loaded after container restart | `make btc-wallet-ready` |
| `Already a wallet loaded` | Wallet already loaded | Normal — ignore |
| `Wallet file verification failed` | Corrupt wallet data | `make btc-reset-data` (destroys chain state) |
| Zero balance after restart | Wallet loaded but not funded | `make btc-mine` |

## Image / build issues

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| OCI labels show `unknown` for revision | Git repo has no commits | Expected on fresh clone with uncommitted state |
| Build context slow (> 5s) | `.dockerignore` missing or wrong | Verify `.dockerignore` contains `**` + `!docker/bitcoin.conf` |
| `failed to solve: failed to read dockerfile` | Wrong `BITCOIN_DOCKERFILE` path | Check `Makefile` variable |
| Base image digest mismatch | Tag was force-pushed upstream | Update digest in `Makefile` with `docker buildx imagetools inspect` |

## Volume / data issues

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Node starts but has 0 blocks after funding | Volume was deleted | `make btc-mine` again |
| Unexpected chain state | Old data from previous test run | `make btc-reset-data` then `make btc-up` |
| Volume not visible in `make btc-docker-state` | Node never started successfully | Check `make btc-logs` |
