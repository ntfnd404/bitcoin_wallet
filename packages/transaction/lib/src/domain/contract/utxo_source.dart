import 'package:transaction/src/domain/value_object/utxo_source_result.dart';

/// Source of UTXO candidates + change address + signing context for a send.
///
/// One implementation per wallet flavour (auto/pinned × Node/HD). The
/// [EligibilityFilteringUtxoSource] decorator wraps any inner source to apply
/// the eligibility filter before candidates reach a coin selector.
abstract interface class UtxoSource {
  Future<UtxoSourceResult> resolve();
}
