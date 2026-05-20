/// Configuration for UTXO eligibility filtering.
///
/// Node wallet and HD wallet use different policies because `scantxoutset`
/// (HD) does not expose per-UTXO confirmations relative to chain tip, while
/// Bitcoin Core's `listunspent` (Node) does.
final class EligibilityPolicy {
  /// Minimum confirmed blocks required. 0 = accept any, including mempool.
  /// Applies only when [confirmations] is non-null on the candidate.
  final int minConfirmations;

  /// When `true`, candidates with `confirmations == null` (unknown — HD wallet
  /// via `scantxoutset`) pass the confirmation check. When `false`, unknown
  /// confirmation candidates are excluded. (G6)
  final bool allowUnknownConfirmations;

  /// Whether to allow dust-value candidates (effectiveSatoshis ≤ 0). Almost
  /// always `false` — dust candidates cost more to spend than they contribute.
  final bool allowDust;

  /// Standard Node wallet policy: confirmed UTXOs only, no dust.
  static const node = EligibilityPolicy(
    minConfirmations: 1,
    allowUnknownConfirmations: false,
  );

  /// HD wallet policy: confirmations unknown (scantxoutset limitation), no dust.
  static const hd = EligibilityPolicy(
    minConfirmations: 0,
    allowUnknownConfirmations: true,
  );

  const EligibilityPolicy({
    required this.minConfirmations,
    required this.allowUnknownConfirmations,
    this.allowDust = false,
  });
}
