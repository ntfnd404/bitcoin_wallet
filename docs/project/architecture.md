# Architecture

Packages-first Flutter workspace monorepo. One app first, explicit module ownership,
layered internals, and lightweight guardrails around imports and topology.

---

## Philosophy

This repository uses a hybrid architecture:

- **Feature-first app** — UI flows live under `lib/feature/`
- **Modular monolith** — business and infrastructure are split into workspace packages
- **Clean Architecture** — dependencies point inward
- **DDD / bounded contexts** — each business package owns its model and use cases
- **Hexagonal** — consumer modules own ports, adapters implement them
- **Hard guardrails** — architecture docs + validator checks + import policy

The main design goal is not “maximum modularity.” The goal is **predictable
growth**: medium and large codebases should gain new capabilities without
collapsing into a shared `domain/` or `data/` dumping ground.

---

## Topology Standard

Durable decision record: [ADR-003](./adr/ADR-003-monorepo-topology-standard.md).

### Scheme A — default

Use this topology by default:

```text
/
  lib/                      # single Flutter app (presentation only)
    core/
    common/
    feature/
  packages/                 # reusable Dart/Flutter packages
  docs/
  test/
  pubspec.yaml              # app + workspace root
```

Rules:

- Start with **one app in the repository root**
- Put reusable business and infrastructure code in **`packages/`**
- Keep `lib/feature/*` app-specific unless a flow becomes truly reusable
- Do **not** introduce top-level `components/` for business code
- Do **not** introduce `apps/` until a second releasable client exists

### Scheme B — escalation path

Move to this only when the repository actually contains multiple products:

```text
/
  apps/
    main_app/
    admin_app/
  packages/
    ...
```

Use `apps/` only when at least one is true:

- there is a second independently releasable Flutter app
- branding / permissions / startup / routing diverge materially
- one app must physically exclude modules that another app includes
- separate teams need isolated app entrypoints and CI lanes

Even after the switch, shared code still belongs in `packages/*`, not in a
shared top-level `features/` folder.

---

## Project Structure

This repository currently and intentionally stays on **Scheme A**.

```text
bitcoin_wallet/
├── lib/
│   ├── core/
│   ├── common/
│   └── feature/
├── packages/
│   ├── address/
│   ├── bitcoin_node/
│   ├── keys/
│   ├── rpc_client/
│   ├── shared_kernel/
│   ├── storage/
│   ├── transaction/
│   ├── ui_kit/
│   └── wallet/
├── docs/
├── test/
└── pubspec.yaml
```

The app at the root is the only client. HD and Node wallets are **trust-model
variants inside the product**, not separate products.

---

## Dependency Graph

Arrow direction: `A -> B` means A depends on B.

```text
shared_kernel -> (none)
rpc_client    -> (none)
ui_kit        -> (none)

keys          -> shared_kernel
storage       -> shared_kernel
wallet        -> shared_kernel, keys
address       -> shared_kernel, keys, wallet
transaction   -> shared_kernel, address
bitcoin_node  -> shared_kernel, rpc_client, wallet, address, transaction

app (lib/)    -> all public package APIs as needed
```

This must remain a **DAG**. If a cycle appears:

1. move only the minimum shared primitive lower,
2. introduce a lightweight value object at the lower layer,
3. or replace the direct dependency with an ID/reference.

Do not solve cycles by creating a generic mega-package.

---

## Package Taxonomy

### Shared kernel

- `shared_kernel`
- tiny primitives and cross-cutting contracts only
- examples: network enum, address type, secure storage interface

Never put large entities, repositories, or use cases here.

### Business packages

- `wallet`
- `address`
- `transaction`
- `keys`

Each business package owns:

- domain entities and value objects
- repository contracts
- data-source contracts owned by the consumer
- application use cases
- internal implementations

### Infrastructure packages

- `bitcoin_node`
- `rpc_client`
- `storage`

Each infrastructure package wraps one external boundary:

- Bitcoin Core RPC
- HTTP transport
- platform secure storage

Infrastructure packages implement ports. They do not own business contracts.

### UI package

- `ui_kit`

`ui_kit` owns design tokens, theme, and generic reusable UI only. It does not
own product workflows or business logic.

---

## Module Ownership

| Package | Owns |
|--------|------|
| `shared_kernel` | tiny shared primitives and contracts |
| `keys` | mnemonic, seed access, derivation services, crypto helpers |
| `wallet` | wallet entities, wallet repositories, create/restore wallet use cases |
| `address` | address entity, address repository, address generation |
| `transaction` | transaction and UTXO domain, send/prepare/scan flows |
| `bitcoin_node` | implementations of remote data-source interfaces |
| `storage` | Flutter secure storage implementation |
| `rpc_client` | JSON-RPC transport |
| `ui_kit` | shared UI building blocks |

Ownership rule: every non-trivial concept has **one home package**. Other
packages consume its public API; they do not re-own the same concept.

---

## Public API Standard

Every package should expose:

- one public barrel: `package:<module>/<module>.dart`
- optional DI entry point: `package:<module>/<module>_assembly.dart`

Everything under `src/` is private implementation detail.

Rules:

- app code imports package barrels, never `package:<module>/src/*`
- packages may use `src/` imports **inside the same package**
- cross-package deep imports are forbidden

---

## Internal Package Structure

Each business package follows this internal shape:

```text
packages/<module>/
├── lib/
│   ├── <module>.dart
│   ├── <module>_assembly.dart
│   └── src/
│       ├── domain/
│       ├── application/
│       └── data/
└── test/
```

Layer responsibilities:

- `domain/` — entities, value objects, contracts, pure policies
- `application/` — use cases and orchestration
- `data/` — implementations, mappers, serializers, adapters internal to the module

Package boundaries answer “who owns this capability?”
Layer boundaries answer “what kind of code is this?”

This is why the repository uses multiple business packages instead of only two
top-level packages called `domain` and `data`.

---

## App Layer Rules

`lib/` is the single app shell on Scheme A.

### `lib/feature/*`

Contains:

- screens and widgets
- BLoC/state/event types
- per-flow DI scopes
- screen-local orchestration when it is still app-specific

Must not contain:

- repository implementations
- domain entities
- cross-package deep imports

### `lib/common/*`

App-local shared helpers only:

- widgets
- extensions
- small utilities

`common/` must not become an unofficial platform shared layer. If a type or UI
primitive is reusable beyond this app shell, promote it into a package.

### `lib/core/*`

Composition root, routing, constants, app-wide adapters, and global concerns
owned by the app shell.

---

## Trust-Model Split

HD and Node wallet behavior stays **inside the relevant business packages**.

Current rule:

- shared domain types stay shared when the difference is representational
- trust-specific orchestration lives under `application/hd/` and `application/node/`
- trust-specific implementations live under `data/hd/` and `data/node/` when needed
- cross-trust imports inside the same package are forbidden

Do **not** split HD and Node into separate apps or separate workspace packages
unless they become separate products with separate release needs.

See [ADR-002](./adr/ADR-002-trust-model-subfolder-split.md).

---

## Import Policy

### Allowed

```text
lib/feature/*            -> package public barrels
lib/feature/*            -> ui_kit
lib/*                    -> lib/core/* and lib/common/*
module/application       -> own domain
module/data              -> own domain
module/data              -> other packages' public APIs when needed
infra package            -> consumer-owned domain contracts it implements
```

### Forbidden

```text
lib/*                    -> package:<module>/src/*
package A                -> package B/src/*
packages/*               -> app code in lib/*
feature X                -> feature Y bloc/domain internals
shared_kernel            -> business package code
application/hd/          -> application/node/
application/node/        -> application/hd/
```

---

## Decision Triggers

### When to create a new package

Create a package only when the code has at least one of these properties:

- clear ownership boundary
- reusable business capability
- isolated external adapter
- separate dependency profile
- meaningful test surface that benefits from modular isolation

Do not create a package for a couple of helpers.

### When to move code from `lib/feature/*` to `packages/*`

Promote it when it becomes:

- reusable across multiple screens or flows,
- business-oriented rather than purely presentational,
- or a likely future cross-app capability.

### When to introduce `apps/`

Only when Scheme B conditions are actually met.

### When to adopt `melos`

Not by default.

Add `melos` only when native pub workspace + `make` become insufficient for:

- filtered multi-package command execution
- shared workspace scripts
- coordinated versioning or publishing
- complex monorepo CI orchestration

Until then, use:

- pub workspace resolution
- package-local tests
- `make`
- validator checks

---

## Guardrails

This standard is enforced by:

- `docs/project/conventions.md`
- `AGENTS.md`
- `CLAUDE.md`
- `.claude/bin/aidd_validate.sh`

The validator checks at minimum:

- workspace package declarations exist
- each workspace package exposes a public barrel
- app and test code do not deep-import `package:<module>/src/*`
- packages do not import app code
- top-level `components/` is not introduced

That keeps the monorepo standard executable instead of purely aspirational.
