import 'package:keys/keys.dart'
    show SigningInputParam, SigningOutput, SignTransactionUseCase;
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart' as tx
    show SigningInput, TransactionSigner;

/// Implements [tx.TransactionSigner] using the HD wallet's mnemonic seed.
///
/// Bridges the `transaction` domain interface to [SignTransactionUseCase]
/// from the `keys` package. Lives in the app layer because it depends on both
/// `transaction` and `keys` packages.
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
      if (changeSat.value > 0)
        SigningOutput(address: changeAddress, amountSat: changeSat),
    ];

    return _signTransaction.call(
      walletId: walletId,
      inputs: keyInputs,
      outputs: outputs,
      bech32Hrp: bech32Hrp,
    );
  }
}
