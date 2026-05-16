import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/transaction.dart' show SigningInput;

void main() {
  group('tx.SigningInput', () {
    test('toString does not expose fields in unsafe format', () {
      const input = SigningInput(
        txid: 'cafebabe',
        vout: 1,
        amountSat: Satoshi(75000),
        address: 'bcrt1qtest',
        derivationIndex: 42,
        addressType: AddressType.nativeSegwit,
      );

      final output = input.toString();

      // derivationIndex is present — safe, non-secret field.
      expect(output, contains('42'));

      // toString matches the known stable pattern — this creates a stable
      // baseline that will fail if a future refactor changes the format
      // in an unreviewed way.
      expect(
        output,
        equals(
          'SigningInput(txid: cafebabe, vout: 1, amountSat: 75000 sat, '
          'address: bcrt1qtest, derivationIndex: 42, addressType: AddressType.nativeSegwit)',
        ),
      );
    });
  });
}
