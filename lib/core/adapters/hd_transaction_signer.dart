import 'package:keys/keys.dart' show SigningInputParam, SigningOutput, SignTransactionUseCase;
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart' as tx show SigningInput, TransactionSigner;

/// Composition adapter: bridges [tx.TransactionSigner] (owned by `transaction`)
/// to [SignTransactionUseCase] (owned by `keys`).
///
/// **Architectural decision (BW-0011, kept as conscious compromise):**
/// This adapter lives in the app layer instead of a dedicated `signing_port`
/// package because it is the *only* cross-package bridge of its kind.
/// Extracting a neutral package for one adapter would be premature abstraction
/// (rule of three). Re-evaluate if 2+ more similar bridges appear — at that
/// point, a `signing_port` package becomes warranted.
///
/// See `docs/project/conventions.md` § App-layer composition adapters.
final class HdTransactionSigner implements tx.TransactionSigner {
  final SignTransactionUseCase _signTransaction;

  const HdTransactionSigner({
    required SignTransactionUseCase signTransaction,
  }) : _signTransaction = signTransaction;

  @override
  Future<String> sign({
    required String walletId,
    required List<tx.SigningInput> inputs,
    required String recipientAddress,
    required Satoshi amountSat,
    required String changeAddress,
    required Satoshi changeSat,
    required String bech32Hrp,
  }) {
    final keyInputs = inputs
        .map(
          (i) => SigningInputParam(
            txid: i.txid,
            vout: i.vout,
            amountSat: i.amountSat,
            type: i.addressType,
            derivationIndex: i.derivationIndex,
          ),
        )
        .toList();

    final outputs = [
      SigningOutput(address: recipientAddress, amountSat: amountSat),
      if (changeSat.value > 0) SigningOutput(address: changeAddress, amountSat: changeSat),
    ];

    return _signTransaction(
      walletId: walletId,
      inputs: keyInputs,
      outputs: outputs,
      bech32Hrp: bech32Hrp,
    );
  }
}
