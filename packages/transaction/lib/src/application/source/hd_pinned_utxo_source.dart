import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/contract/utxo_source.dart';
import 'package:transaction/src/domain/entity/utxo.dart';
import 'package:transaction/src/domain/exception/transaction_exception.dart';
import 'package:transaction/src/domain/value_object/coin_candidate.dart';
import 'package:transaction/src/domain/value_object/signing_context.dart';
import 'package:transaction/src/domain/value_object/signing_input.dart';
import 'package:transaction/src/domain/value_object/utxo_source_result.dart';
import 'package:wallet/wallet.dart';

/// UTXO source for the HD Wallet (caller-pinned-inputs variant).
///
/// Builds an address → entry lookup from [AddressRepository.getAddresses] and
/// resolves each pinned [Utxo] to a [CoinCandidate] + [SigningInput]. If a
/// pinned input references an address absent from the lookup, throws
/// [UnknownPinnedInputAddressException] carrying `{txid, vout, address}` so
/// the UI can surface a precise error.
///
/// Change address mirrors [HdAutoUtxoSource]: highest-derivation-index native
/// segwit entry (or empty string when no addresses exist). The caller-supplied
/// `pinnedInputs` list is never sorted or mutated in place.
final class HdPinnedUtxoSource implements UtxoSource {
  final String _walletId;
  final List<Utxo> _pinnedInputs;
  final AddressRepository _addressRepository;

  const HdPinnedUtxoSource({
    required String walletId,
    required List<Utxo> pinnedInputs,
    required AddressRepository addressRepository,
  })  : _walletId = walletId,
        _pinnedInputs = pinnedInputs,
        _addressRepository = addressRepository;

  @override
  Future<UtxoSourceResult> resolve() async {
    try {
      final entries = await _addressRepository.getAddresses(_walletId);
      final nativeSegwit = entries.where((e) => e.type == AddressType.nativeSegwit).toList();

      final addressLookup = {for (final e in entries) e.value: e};

      final candidates = <CoinCandidate>[];
      final signingInputs = <(String, int), SigningInput>{};

      for (final u in _pinnedInputs) {
        final pinnedAddress = u.address;
        if (pinnedAddress == null || !addressLookup.containsKey(pinnedAddress)) {
          throw UnknownPinnedInputAddressException(
            txid: u.txid,
            vout: u.vout,
            address: pinnedAddress ?? '',
          );
        }

        final entry = addressLookup[pinnedAddress]!;
        candidates.add(
          CoinCandidate(
            txid: u.txid,
            vout: u.vout,
            amountSat: u.amountSat,
            age: u.confirmations,
            scriptType: entry.type,
            scriptPubKeyHex: u.scriptPubKey,
            confirmations: u.confirmations,
          ),
        );
        signingInputs[(u.txid, u.vout)] = SigningInput(
          txid: u.txid,
          vout: u.vout,
          amountSat: u.amountSat,
          address: pinnedAddress,
          derivationIndex: entry.index,
          addressType: entry.type,
        );
      }

      // Local mutable copy used solely for the change-address sort —
      // the caller-supplied list is never mutated.
      final changeAddress = nativeSegwit.isEmpty
          ? ''
          : (List.of(nativeSegwit)..sort((a, b) => b.index.compareTo(a.index))).first.value;

      return UtxoSourceResult(
        candidates: candidates,
        changeAddress: changeAddress,
        signingContext: HdSigningContext(signingInputs),
      );
    } on TransactionException {
      rethrow;
    } on AddressException catch (_, stack) {
      Error.throwWithStackTrace(const TransactionPreparationException(), stack);
    }
  }
}
// ignore_for_file: prefer_initializing_formals

