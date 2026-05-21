import 'package:keys/src/application/signing_input_param.dart';
import 'package:keys/src/domain/entity/signing_input.dart';
import 'package:keys/src/domain/entity/signing_output.dart';
import 'package:keys/src/domain/exception/keys_exception.dart';
import 'package:keys/src/domain/repository/seed_repository.dart';
import 'package:keys/src/domain/service/key_derivation_service.dart';
import 'package:keys/src/domain/service/transaction_signing_service.dart';

export 'signing_input_param.dart';

/// Signs a P2WPKH transaction using keys derived from the wallet seed.
///
/// Private keys are held in memory only for the duration of the call.
///
/// Throws [KeysSeedNotFoundException] if no seed is found for [walletId].
/// Throws [KeysDerivationException] if key derivation fails.
/// Throws [KeysSigningException] if signing fails.
final class SignTransactionUseCase {
  final SeedRepository _seedRepository;
  final KeyDerivationService _derivation;
  final TransactionSigningService _signing;

  const SignTransactionUseCase({
    required this._seedRepository,
    required this._derivation,
    required this._signing,
  });

  Future<String> call({
    required String walletId,
    required List<SigningInputParam> inputs,
    required List<SigningOutput> outputs,
    required String bech32Hrp,
  }) async {
    final mnemonic = await _seedRepository.getSeed(walletId);
    if (mnemonic == null) {
      throw const KeysSeedNotFoundException();
    }

    try {
      final signingInputs = inputs.map((param) {
        final privateKey = _derivation.derivePrivateKey(
          mnemonic,
          param.type,
          param.derivationIndex,
        );
        final publicKey = _derivation.derivePublicKey(
          mnemonic,
          param.type,
          param.derivationIndex,
        );

        return SigningInput(
          txid: param.txid,
          vout: param.vout,
          amountSat: param.amountSat,
          privateKey: privateKey,
          publicKey: publicKey,
        );
      }).toList();

      return _signing.signP2wpkh(
        inputs: signingInputs,
        outputs: outputs,
        bech32Hrp: bech32Hrp,
      );
    } on StateError catch (_, stack) {
      // Crypto internals (bip32, key derivation) threw StateError.
      // SECURITY: do NOT log or inspect the caught exception — it may carry key material.
      Error.throwWithStackTrace(const KeysDerivationException(), stack);
    } catch (_, stack) {
      // Broad catch — security-first policy (Rule SB-5): C1 vocabulary isolation,
      // C2 key-material suppression (discard message via _), C3 stack preserved,
      // C4 caller distinguishes all three exception types. ArgumentError → KeysSigningException
      // is the accepted security-over-propagation trade-off.
      Error.throwWithStackTrace(const KeysSigningException(), stack);
    }
  }
}
