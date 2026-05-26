# Project Vision

Last reviewed: 2026-05-26

## What this project is

Bitcoin Wallet is a Flutter learning project that pairs a mobile/desktop wallet app with a local Bitcoin Core node running in `regtest` Docker. It exposes two wallet models side by side: a **Node Wallet** where Bitcoin Core custodies the keys via RPC, and an **HD Wallet** where the app owns the mnemonic and performs derivation, PSBT assembly, and signing locally. The core promise is a reproducible, end-to-end sandbox where a single developer can exercise the full lifecycle of a Bitcoin transaction — address derivation, UTXO selection, coin-selection strategy, fee estimation, signing, broadcast, and confirmation — against a real node without touching mainnet.

The project doubles as a real-world testbed for Claude-Native Enterprise AIDD v3.2: every feature ships through the documented ticket → idea → PRD → research → plan → implement → review → security review → QA → summary pipeline, with lanes (Trivial / Professional / Critical) gating depth of review.

## Non-goals

- Not a production wallet. No mainnet support is planned; `regtest` is the only target environment.
- Not a custodial service or back-end product. There is no server component beyond the local Bitcoin Core node.
- Not a multi-user system. Single developer, single device.
- Not a portfolio / market-data / fiat-conversion app. Scope is strictly transaction lifecycle.
- Not a cross-wallet interop demo. PSBT export/import to third-party signers is out of scope.
- Not a security-audited reference. Cryptographic choices follow Bitcoin Core conventions but are not independently reviewed.

## Stakeholders

- **Product owner / sole developer** — Oleg. Sets scope, approves PRDs, runs `[USER ACTION]` gates, and owns ship decisions.
- **AIDD orchestrator (Claude Code)** — drives the workflow loop, surfaces diffs, captures verdicts, and routes between specialist agents.
- **Specialist agents** — analyst, researcher, planner, implementer, reviewer, security-reviewer, qa, spec-critic. Each owns one artifact contract.
- **End user (hypothetical)** — modeled in user stories during PRD authoring; never an actual external user in this project.

## Architecture summary

- One Flutter app at the repository root with reusable code factored into workspace packages under `packages/`.
- Workspace packages model business ownership: `address`, `bitcoin_node`, `keys`, `rpc_client`, `shared_kernel`, `storage`, `transaction`, `ui_kit`, `wallet`.
- DDD layering: domain (pure Dart, no Flutter) → application (use cases, BLoC) → infrastructure (RPC, storage, signing adapters) → presentation (widgets, screens, scopes).
- Strategy pattern is preferred over `switch` on enum/sealed types in domain code; a single localized `switch(wallet)` is permitted only in composition roots (e.g. `TransactionAssembly`).
- State management: BLoC only. No Cubit. Each BLoC lives in its own sub-feature folder; BLoCs are constructed exclusively through `Scope.newBloc` factories.
- BLoC state carries only persistent UI signals; ephemeral effects (navigation, snack bars, focus) flow through an action stream; cross-feature messaging uses an EventBus, never `BlocListener`.
- Dependency injection is hand-rolled via `Scope` widgets and `AppDependenciesBuilder`. No `GetIt`. No `print` / `log` calls in adapters.
- Test layout: helpers (fakes/stubs/mocks) live in `test/helpers/` or `test/<module>/helpers/`, never inline in test files.
- See `docs/project/conventions.md` for package boundaries and import rules, and `docs/project/code-style-guide.md` for formatting and naming.

## Why this approach

The project is run as a single-developer learning environment, which makes it tempting to skip process. The opposite choice was made deliberately: AIDD v3.2 with strict lanes, structured acceptance criteria, and artifact-bound gates is dog-fooded on every ticket so the methodology itself is being shaped by real friction. Lanes (Trivial for typo-fixes, Professional for default work, Critical for wallet / keys / crypto / signing / storage migration / API contracts) tune review depth to risk; spec-critic and security-reviewer gates exist precisely because the domain (Bitcoin custody) punishes silent specification drift.
