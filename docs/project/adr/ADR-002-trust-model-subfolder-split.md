# ADR-002: Trust-Model Subfolder Split (HD vs Node)

Status: `accepted`
Ticket: BW-0005
Phase: feature
Lane: Critical
Workflow Version: 3
Owner: Architect
Date: 2026-04-25

---

## Context

The wallet supports two trust models:

- **HD (non-custodial):** the application owns the mnemonic, derives keys, and signs locally.
- **Node (custodial):** Bitcoin Core owns the keys; the application is a UI over an RPC.

These models share the core domain types — a sealed `Wallet` hierarchy with `HdWallet` and `NodeWallet` branches in `packages/wallet/lib/src/domain/entity/`, and an `Address` value object in `packages/address/lib/src/domain/entity/address.dart` that carries `derivationPath` (non-null for HD, null for Node) — but their `data/` and `application/` layer logic diverges sharply (use cases, repositories, data sources).

Today HD and Node code interleave in the same folders. Cross-trust imports (HD code importing Node helpers, or vice versa) are caught only by code review. There is no folder-level signal of which trust model a file belongs to. A misplaced import that lets Node code reach HD signing context — or that lets HD code reach a Node RPC session — is a privacy/security regression even if it does not change runtime behaviour.

BW-0005 Phase 3 introduces a structural boundary. This ADR records the durable architectural commitment behind that work, so that:

- The Phase 3 implementation has a single referenceable "why."
- Future contributors adding a third trust model (e.g. multisig, hardware wallet) follow the same pattern instead of inventing a new one.
- Reviewer checklists for any `wallet`, `transaction`, `address` PR can cite this decision rather than re-derive it.

---

## Options Considered

### A. Subfolders within the same package, `data/` + `application/` only, `domain/` shared

Introduce `hd/` and `node/` subfolders inside the `data/` and `application/` layers of `wallet`, `transaction`, and `address`. Domain layers stay shared.

- **Pros**
  - Shared sealed `Wallet` hierarchy and nullable `Address.derivationPath` already encode the trust distinction at the type level — no need to duplicate domain entities.
  - Greppable structural boundary: `grep` for cross-trust imports is exact and CI-friendly.
  - Minimal package-graph churn — no new workspace packages, no new `pubspec.yaml` edges.
  - Truly trust-agnostic orchestrators (e.g. `WalletRepositoryImpl` which implements both `HdWalletRepository` and `NodeWalletRepository`) stay at the layer root and remain straightforward to author.
  - Adding a third trust model later is local: a new `multisig/` subfolder alongside `hd/` and `node/`.
- **Cons**
  - Enforcement is greppable, not compiler-enforced. Relies on reviewer discipline plus an optional future static-analysis rule.

### B. Separate workspace packages (`hd_wallet`, `node_wallet`, `hd_transaction`, `node_transaction`, `hd_address`, `node_address`)

Promote the trust boundary to a package boundary. Each trust model gets its own workspace package with its own `pubspec.yaml`.

- **Pros**
  - Compiler-enforced boundary via `pubspec.yaml` dependencies — a forbidden cross-trust import simply does not resolve.
- **Cons**
  - Domain entities (`Wallet`, `Address`) would need to be duplicated, or moved down into a shared lower package — both choices add friction and re-introduce the synchronisation debt that BW-0005 Phase 2 is removing for `HdAddressEntry`.
  - Doubles the workspace package count (from 9 to 12+) without adding any new behavioural boundary.
  - High import-friction on every shared use case that legitimately bridges trust models (e.g. listing all wallets, computing total balance).
  - Over-strong boundary for code that legitimately shares contracts (e.g. `Address` is the same value object regardless of who derived it).

### C. Subfolders in all three layers (`domain/` also split into `hd/` / `node/`)

Maximum structural separation: every layer of every trust-aware package has parallel `hd/` and `node/` subtrees.

- **Pros**
  - Total structural symmetry; no special case for `domain/`.
- **Cons**
  - Forces splitting `Wallet` into `HdWallet`/`NodeWallet` as separate top-level types and `Address` into `HdAddress`/`NodeAddress` — but the entities are already differentiated by sealed-class branches and a nullable field. Splitting them creates two parallel value-object families with synchronisation debt: exactly the smell that BW-0005 Phase 2 removes for `HdAddressEntry`.
  - Every cross-trust query (e.g. "list all wallets") requires a third shared type just to express the union.
  - The trust difference at the domain level is *fields*, not *behaviour*. Splitting on field difference violates the same DDD principle that says "model behaviour, not data."

---

## Decision

**Choose Option A.**

Concrete invariants this decision commits to:

- Inside any package that has trust-specific code (currently `wallet`, `transaction`, `address`), the `data/` and `application/` layers contain `hd/` and `node/` subfolders. Trust-agnostic files at those layers stay at the layer root.
- `hd/` files inside a package may import only from: that package's own `hd/`, that layer's root (shared), `domain/`, and other packages.
- `node/` files inside a package may import only from: that package's own `node/`, that layer's root (shared), `domain/`, and other packages.
- `hd/` ↔ `node/` cross-imports inside the same package are forbidden.
- `domain/` layers of `wallet`, `transaction`, `address` are **not** subfolder-split. Entities and contracts stay shared; the trust distinction is carried by the existing sealed `Wallet` hierarchy and by `Address.derivationPath` (null for Node, non-null for HD).
- The `keys` package remains the only signing-capable code. Trust model is a property of the *consumer* of `keys`, not of `keys` itself.
- Truly trust-agnostic orchestrators (e.g. `WalletRepositoryImpl` which implements both `HdWalletRepository` and `NodeWalletRepository`) stay at the layer root and continue to wire trust-specific dependencies via DI.

---

## Consequences

- **Phase 3 implements the split.** Success metrics in `docs/BW-0005/prd/BW-0005-phase-3.prd.md` operationalise the invariants above (greppable cross-import checks, `dart pub deps` clean, barrel symbol-set unchanged).
- **Adding a third trust model** (e.g. multisig, hardware wallet): add a `multisig/` subfolder alongside `hd/` and `node/` in each affected package's `data/` and `application/` layers. Do **not** introduce a new workspace package unless behavioural requirements force it (e.g. an external SDK that pulls in conflicting dependencies).
- **Static-analysis enforcement is a recommended follow-up.** A `dart_code_metrics` rule (or the analyzer's `avoid-relative-lib-imports` plus a custom check) can promote the greppable boundary to a CI-enforced one. Tracked outside BW-0005.
- **Reviewer responsibility.** Any PR that touches `wallet`, `transaction`, or `address` `data/` or `application/` layers must verify: (a) new files land in the correct subfolder; (b) imports respect the boundary; (c) shared files stay shared.
- **Supersession bar is high.** This ADR may be superseded if a future domain change forces *behaviourally* different entities per trust model — not merely *field* differences. The `derivationPath?` pattern handles field-level differences; the `Wallet` sealed hierarchy handles type-tagged differences. Until something requires a method that genuinely differs in implementation per trust model, splitting `domain/` is the wrong move.
- **Interaction with `HdAddressEntry` removal (Phase 2).** That removal demonstrates the same principle on a smaller scale: a parallel value-object family is a smell when no architectural cycle forces it. After Phase 2, `Address` is the canonical address type across both trust models — confirming Option A's premise that domain-level sharing is sustainable.
