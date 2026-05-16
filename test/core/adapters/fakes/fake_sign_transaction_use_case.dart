import 'package:keys/keys.dart' show SigningInputParam, SigningOutput;

/// Configurable fake implementing the [SignTransaction] typedef call signature.
///
/// Used in [HdTransactionSigner] tests. Not a subclass of [SignTransactionUseCase]
/// (which is `final`) — matches the typedef by structural compatibility.
final class FakeSignTransactionUseCase {
  String? result;
  Object? throws;

  /// Captured arguments from the last [call] invocation.
  List<SigningInputParam>? capturedInputs;
  String? capturedWalletId;
  List<SigningOutput>? capturedOutputs;
  String? capturedBech32Hrp;

  FakeSignTransactionUseCase({this.result, this.throws});

  Future<String> call({
    required String walletId,
    required List<SigningInputParam> inputs,
    required List<SigningOutput> outputs,
    required String bech32Hrp,
  }) async {
    capturedWalletId = walletId;
    capturedInputs = inputs;
    capturedOutputs = outputs;
    capturedBech32Hrp = bech32Hrp;
    final t = throws;
    if (t != null) throw t;

    return result ?? 'deadbeef';
  }
}
