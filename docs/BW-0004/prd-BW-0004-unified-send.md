# BW-0004 — Unified Send with UTXO Selection

Status: `DRAFT`
Lane: `Critical`

---

## Vision

Replace the two separate send flows (node send + HD manual UTXO) with a single unified send
feature that supports three UTXO selection modes. The user picks how UTXOs are selected;
the signing and broadcast pipeline is the same regardless of mode.

---

## Problem

Currently there are two disconnected send flows:

| Flow | Location | Limitation |
|------|----------|------------|
| Node / auto send | `feature/send/` | Opaque coin selection, no user control |
| HD manual UTXO | `feature/signing/manual_utxo/` | Temporary scaffolding, HD-only, no strategy awareness |

Neither flow explains _why_ certain UTXOs were chosen.

---

## Solution: Three UTXO Selection Modes

```
feature/send/
  auto/          ← algorithm selects best strategy + explains reasoning
  strategy/      ← user picks a named strategy, sees its trade-offs
  manual/        ← user handpicks UTXOs from the UTXO set
```

All three modes produce identical output: a list of signed inputs → broadcast.

---

## Mode 1 — Auto (Smart Selection)

The app analyses the current UTXO set and wallet state, picks the best strategy, and
**explains the reasoning** to the user before confirmation.

**Algorithm inputs:**
- Current UTXO set (count, amounts, ages)
- Target amount + fee rate
- Mempool state (congestion level)
- Wallet privacy preferences (future)

**Output shown to user:**
```
Selected strategy: Branch and Bound
Reason: minimises change output — saves 330 sat in future fees and
        reduces UTXO set size from 12 → 8.
Alternatives considered:
  • FIFO — would create 0.0003 BTC change (adds dust)
  • Largest-first — overpays by 1 200 sat
```

**Confirmation step:** user sees the reasoning, can switch to Strategy or Manual mode.

---

## Mode 2 — Strategy Selection

User picks a named coin selection strategy. The app shows each strategy's trade-offs
before the user confirms.

**Supported strategies (v1):**

| Strategy | Description | Best when |
|----------|-------------|-----------|
| Branch and Bound (BnB) | Finds exact match, zero change | Exact amounts available |
| Largest-first | Spend biggest UTXOs first | Reducing UTXO set |
| Smallest-first | Spend smallest UTXOs first | Consolidation |
| FIFO | Oldest UTXOs first | Coin age / privacy |
| Random | Non-deterministic selection | Privacy |

Each strategy card shows:
- Estimated fee
- Change amount (or "no change")
- Effect on UTXO set size
- One-line trade-off explanation

---

## Mode 3 — Manual UTXO Selection

User sees the full UTXO set as a checklist. Selects individual UTXOs. App shows:
- Running total selected
- Estimated fee for selection
- Change that will be returned
- Warning if selection is suboptimal (e.g. dust change)

This mode absorbs the current `signing/manual_utxo/` scaffolding.

---

## Architecture

### Domain layer (`packages/transaction`)

```dart
// New: strategy abstraction
abstract interface class UtxoSelectionStrategy {
  String get name;
  String get description;
  UtxoSelectionResult select(UtxoSelectionParams params);
}

// New: auto-selector
abstract interface class AutoUtxoSelector {
  AutoSelectionResult selectBest(UtxoSelectionParams params);
  // Returns chosen strategy + explanation + alternatives
}

class UtxoSelectionParams {
  final List<Utxo> available;
  final Satoshi target;
  final Satoshi feeRatePerVbyte;
}

class UtxoSelectionResult {
  final List<Utxo> selected;
  final Satoshi estimatedFee;
  final Satoshi change;
}

class AutoSelectionResult {
  final UtxoSelectionStrategy chosen;
  final UtxoSelectionResult result;
  final String reasoning;           // human-readable explanation
  final List<AlternativeResult> alternatives;
}
```

### Feature layer (`feature/send/`)

```
feature/send/
  common/
    model/        ← SendParams, SendMode enum
    widget/       ← UtxoChip, StrategyCard, ReasoningPanel
  auto/
    bloc/         ← AutoSendBloc
    view/screen/  ← AutoSendScreen
    di/           ← AutoSendScope
  strategy/
    bloc/         ← StrategySendBloc
    view/screen/  ← StrategySendScreen
    di/           ← StrategySendScope
  manual/
    bloc/         ← ManualSendBloc  (absorbs SigningBloc from manual_utxo)
    view/screen/  ← ManualSendScreen
    di/           ← ManualSendScope
```

### Entry point

`SendScreen` (existing) becomes a mode selector — three tabs or a picker:
```
[ Auto ] [ Strategy ] [ Manual ]
```

---

## Out of Scope (BW-0004 v1)

- Privacy / coin control labelling
- Fee bumping (RBF / CPFP)
- Multi-recipient transactions
- Batch sending

---

## Migration

1. Implement `UtxoSelectionStrategy` + `AutoUtxoSelector` in `packages/transaction`
2. Implement `auto/`, `strategy/`, `manual/` sub-features under `feature/send/`
3. Wire `SendScreen` as mode selector
4. Delete `feature/signing/manual_utxo/` (absorbed into `feature/send/manual/`)
5. Update `app_router_delegate.dart` — replace `ManualUtxoScope` with scopes from `feature/send/`

---

## Open Questions

- Should Auto mode skip the explanation screen and go straight to confirmation for
  experienced users? (preference setting)
- Fee rate source: fixed default, user input, or mempool API estimate?
- Should strategy selection persist across sessions?
