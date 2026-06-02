import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/contract/utxo_source.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/gateway/utxo_scan_gateway.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/signer_payload.dart';
import 'package:transaction/src/domain/value_object/signing_input.dart';
import 'package:transaction/src/domain/value_object/utxo_source_result.dart';
import 'package:wallet/wallet.dart';

/// UTXO source for the HD Wallet (auto-selection variant).
///
/// Steps performed by [resolve]:
/// 1. Load all stored HD addresses; keep only native-segwit entries.
/// 2. Scan the UTXO set for those addresses.
/// 3. Sort scanned UTXOs by block height ASC (oldest first) — assigns each
///    candidate an `age` rank (oldest = highest rank).
/// 4. Build `signingInputs` keyed by `(txid, vout)` for every scanned UTXO
///    whose `address` resolves to a known HD entry.
/// 5. Change address = highest-derivation-index native-segwit entry.
///
/// Eligibility filtering belongs to [EligibilityFilteringUtxoSource].
final class HdAutoUtxoSource implements UtxoSource {
  final String _walletId;
  final AddressRepository _addressRepository;
  final UtxoScanGateway _utxoScanGateway;

  const HdAutoUtxoSource({
    required this._walletId,
    required this._addressRepository,
    required this._utxoScanGateway,
  });

  @override
  Future<UtxoSourceResult> resolve() async {
    try {
      // 1. Load all HD addresses; keep only native-segwit entries.
      final entries = await _addressRepository.getAddresses(_walletId);
      final nativeSegwit = entries.where((e) => e.type == AddressType.nativeSegwit).toList();

      // 2. Scan UTXO set for those addresses.
      final addressStrings = nativeSegwit.map((e) => e.value).toList();
      final scanned = await _utxoScanGateway.scanForAddresses(addressStrings);

      final addressLookup = {for (final e in nativeSegwit) e.value: e};

      // 3. Sort by block height ASC — oldest UTXO gets highest age rank.
      scanned.sort((a, b) => a.height.compareTo(b.height));
      final sortedByHeight = scanned;

      // 4. Map to CoinCandidate + build signingInputs keyed by (txid, vout).
      final candidates = <CoinCandidate>[];
      final signingInputs = <(String, int), SigningInput>{};

      for (var i = 0; i < sortedByHeight.length; i++) {
        final u = sortedByHeight[i];
        final age = sortedByHeight.length - i;

        final entry = u.address != null ? addressLookup[u.address] : null;
        candidates.add(
          CoinCandidate(
            txid: u.txid,
            vout: u.vout,
            amountSat: u.amountSat,
            age: age,
            scriptType: entry?.type ?? AddressType.nativeSegwit,
            scriptPubKeyHex: u.scriptPubKeyHex,
          ),
        );

        if (entry != null) {
          signingInputs[(u.txid, u.vout)] = SigningInput(
            txid: u.txid,
            vout: u.vout,
            amountSat: u.amountSat,
            address: u.address!,
            derivationIndex: entry.index,
            addressType: entry.type,
          );
        }
      }

      // 5. Change address = highest-derivation-index native-segwit entry.
      final changeAddress = nativeSegwit.isEmpty
          ? ''
          : (nativeSegwit..sort((a, b) => b.index.compareTo(a.index))).first.value;

      return UtxoSourceResult(
        candidates: candidates,
        changeAddress: changeAddress,
        signingContext: HdSignerPayload(signingInputs),
      );
    } on TransactionException {
      rethrow;
    } on AddressException catch (_, stack) {
      Error.throwWithStackTrace(const TransactionPreparationException(), stack);
    }
  }
}
