# Upgrade Checklist

Use this checklist when upgrading Bitcoin Core. Check off each step as it is completed.

## Pre-upgrade

- [ ] Note current version: `BITCOIN_CORE_VERSION = ___`
- [ ] Note current digest: `sha256:___`
- [ ] Confirm Docker is running: `docker info`
- [ ] Confirm target version exists on Docker Hub: `docker buildx imagetools inspect ruimarinho/bitcoin-core:<target>`

## Upgrade steps

- [ ] Got manifest list digest for `<new-version>`
- [ ] Updated `BITCOIN_CORE_VERSION` in `Makefile`
- [ ] Updated `sha256:` digest in `BITCOIN_BASE_IMAGE` in `Makefile`
- [ ] `make btc-build` succeeded
- [ ] `make btc-restart` succeeded
- [ ] `make btc-wallet-ready` succeeded
- [ ] `make btc-status` shows correct chain and block height
- [ ] OCI labels verified: `docker inspect bitcoin-wallet-regtest:<new-version>`

## Post-upgrade

- [ ] `docs/phases/progress.md` updated with upgrade note
- [ ] `make btc-mine` works (quick smoke test)
- [ ] `make btc-balance` shows correct balance
