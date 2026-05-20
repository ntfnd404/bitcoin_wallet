import 'package:transaction/transaction.dart';

/// Fake [BlockGenerationGateway] for [RegtestMiningBloc] tests.
final class FakeBlockGenerationGateway implements BlockGenerationGateway {
  String? capturedAddress;
  int? capturedCount;

  /// Set to [Exception] for domain errors or [Error] for programmer errors.
  Object? throwsValue;

  @override
  Future<List<String>> generateToAddress(int count, String address) async {
    capturedAddress = address;
    capturedCount = count;

    final t = throwsValue;
    if (t != null) throw t;

    return const ['blockhash_fake'];
  }
}
