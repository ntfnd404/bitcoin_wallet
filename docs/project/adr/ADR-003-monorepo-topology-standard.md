# ADR-003: Monorepo Topology Standard

Status: accepted
Ticket: none
Phase: project
Lane: Critical
Workflow Version: 3
Owner: Architect
Date: 2026-04-27

---

## Context

The repository already uses a Flutter workspace with multiple packages, but the
project documents were not fully aligned on what the long-term topology should
be.

The open questions were structural, not cosmetic:

- should the repository start with one app or with `apps/*`
- should reusable code live in `packages/` or a broader `components/` layer
- should the codebase collapse into only two large top-level packages such as
  `domain` and `data`
- should `melos` be part of the default stack

This decision needs to be durable because it affects:

- how new features are placed
- when new packages are created
- how medium and large teams divide ownership
- how the codebase scales without architecture drift

---

## Options Considered

### A. One app first, reusable code in `packages/`, multi-app only when needed

- **Pros**
  - Matches the current product reality: one Flutter app with multiple trust models
  - Keeps startup complexity low while preserving clear package ownership
  - Scales cleanly to a later `apps/*` transition without rewriting package boundaries
  - Prevents premature shared-feature and app-shell abstraction
- **Cons**
  - Requires discipline to decide when app-local code graduates into a package

### B. Start with `apps/*` from day one

- **Pros**
  - Multi-app topology is ready immediately
  - White-label or admin/client expansion is straightforward if it actually arrives
- **Cons**
  - Adds shell, routing, CI, and reuse complexity before the repository needs it
  - Encourages shared app-layer abstractions too early
  - Solves a future possibility instead of a current product boundary

### C. Keep only two large top-level packages, `domain` and `data`

- **Pros**
  - Simple to explain at a high level
  - Layering is obvious
- **Cons**
  - Hides real bounded-context ownership
  - Encourages god-packages and cross-module entanglement
  - Scales poorly in medium and large codebases where ownership matters more than layer labels alone

---

## Decision

Choose **Option A**.

The standard is:

- default to **one Flutter app at the repository root**
- place reusable code in **`packages/`**
- model business ownership with **multiple bounded-context packages**, not with only `domain` and `data`
- keep `lib/feature/*` as the app presentation layer
- introduce `apps/` only when a second independently releasable app actually exists
- keep trust-model splits such as HD vs Node **inside business packages**, not as separate apps by default
- use native pub workspace support and `make` as the default operational stack
- do **not** adopt `melos` by default
- do **not** introduce a top-level `components/` directory for business modules

Implementation-level consequences of the decision:

- each workspace package exposes a public barrel and may expose an assembly entry point
- everything under `src/` is internal to that package
- app and test code must not deep-import `package:<module>/src/*`
- workspace packages must not import app code from `lib/`

---

## Consequences

- The repository stays on the current single-app topology and does not create `apps/` now.
- `docs/project/architecture.md`, `docs/project/conventions.md`, `AGENTS.md`, and `CLAUDE.md` become aligned around the same monorepo model.
- Validator checks may enforce topology and import guardrails so that the standard is executable.
- Future growth remains flexible:
  - add a package when a new bounded context or external adapter appears
  - add `apps/` only when product topology truly changes
  - add `melos` only when workspace operations become materially painful without it
- The main trade-off is intentional discipline: developers lose some freedom to place code “wherever it fits,” but gain predictable scaling and clearer ownership.
