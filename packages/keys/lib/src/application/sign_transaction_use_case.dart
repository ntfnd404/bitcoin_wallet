import 'package:keys/src/application/signing_input_param.dart';
import 'package:keys/src/domain/entity/signing_input.dart';
import 'package:keys/src/domain/entity/signing_output.dart';
import 'package:keys/src/domain/repository/seed_repository.dart';
import 'package:keys/src/domain/service/key_derivation_service.dart';
import 'package:keys/src/domain/service/transaction_signing_service.dart';

export 'signing_input_param.dart';

/// Signs a P2WPKH transaction using keys derived from the wallet seed.
///
/// Private keys are held in memory only for the duration of the call.
final class SignTransactionUseCase {
  final SeedRepository _seedRepository;
  final KeyDerivationService _derivation;
  final TransactionSigningService _signing;

  const SignTransactionUseCase({
    required SeedRepository seedRepository,
    required KeyDerivationService derivation,
    required TransactionSigningService signing,
  })  : _seedRepository = seedRepository,
        _derivation = derivation,
        _signing = signing;

  Future<String> call({
    required String walletId,
    required List<SigningInputParam> inputs,
    required List<SigningOutput> outputs,
    required String bech32Hrp,
  }) async {
    final mnemonic = await _seedRepository.getSeed(walletId);
    if (mnemonic == null) {
      throw StateError('No seed found for wallet $walletId');
    }

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
  }
}
