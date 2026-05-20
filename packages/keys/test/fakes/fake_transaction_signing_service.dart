import 'package:keys/src/domain/entity/signing_input.dart';
import 'package:keys/src/domain/entity/signing_output.dart';
import 'package:keys/src/domain/service/transaction_signing_service.dart';

final class FakeTransactionSigningService implements TransactionSigningService {
  String? signResult;
  Object? signThrows;

  FakeTransactionSigningService({this.signResult, this.signThrows});

  @override
  String signP2wpkh({
    required List<SigningInput> inputs,
    required List<SigningOutput> outputs,
    required String bech32Hrp,
    int version = 2,
    int locktime = 0,
  }) {
    final throws = signThrows;
    if (throws != null) throw throws;

    return signResult ?? 'deadbeef';
  }
}
