import 'package:transaction/transaction.dart';

final class FakeBlockGenerationGateway implements BlockGenerationGateway {
  @override
  Future<List<String>> generateToAddress(int count, String address) async => const [];
}
