/// How the user's UTXO selection strategy is chosen.
///
/// [auto] — `recommendStrategy()` picks the best result by fee/inputs/change.
/// [manual] — user explicitly picked a specific strategy from the comparison table.
enum CoinSelectionMode { auto, manual }
