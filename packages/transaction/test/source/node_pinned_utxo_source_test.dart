import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/src/application/source/node_pinned_utxo_source.dart';
import 'package:transaction/transaction.dart';

import '../fakes/fake_node_transaction_gateway.dart';

void main() {
  late FakeNodeTransactionGateway gateway;

  setUp(() {
    gateway = FakeNodeTransactionGateway();
  });

  group('NodePinnedUtxoSource', () {
    test('maps pinnedInputs one-to-one into candidates', () async {
      final inputs = [
        _utxo(txid: 'a', sat: 1000),
        _utxo(txid: 'b', sat: 2000),
        _utxo(txid: 'c', sat: 3000),
      ];

      final source = NodePinnedUtxoSource(
        walletName: 'w',
        pinnedInputs: inputs,
        nodeTransactionGateway: gateway,
      );

      final result = await source.resolve();

      expect(result.candidates, hasLength(3));
      expect(result.candidates.map((c) => c.txid).toList(), equals(['a', 'b', 'c']));
    });

    test('does not filter non-spendable inputs (caller invariant)', () async {
      final inputs = [
        _utxo(txid: 'a', sat: 1000, spendable: false),
        _utxo(txid: 'b', sat: 2000),
      ];

      final source = NodePinnedUtxoSource(
        walletName: 'w',
        pinnedInputs: inputs,
        nodeTransactionGateway: gateway,
      );

      final result = await source.resolve();

      expect(result.candidates, hasLength(2));
      expect(result.candidates.map((c) => c.txid).toList(), equals(['a', 'b']));
    });

    test('signingContext is NodeSignerPayload', () async {
      final source = NodePinnedUtxoSource(
        walletName: 'w',
        pinnedInputs: const [],
        nodeTransactionGateway: gateway,
      );

      final result = await source.resolve();

      expect(result.signingContext, isA<NodeSignerPayload>());
    });

    test('changeAddress comes from gateway', () async {
      gateway.newAddressResult = 'bcrt1qchange-pinned';

      final source = NodePinnedUtxoSource(
        walletName: 'w',
        pinnedInputs: const [],
        nodeTransactionGateway: gateway,
      );

      final result = await source.resolve();

      expect(result.changeAddress, equals('bcrt1qchange-pinned'));
    });

    test('wraps gateway generic exception in TransactionPreparationException', () async {
      gateway.newAddressThrows = Exception('rpc down');

      final source = NodePinnedUtxoSource(
        walletName: 'w',
        pinnedInputs: const [],
        nodeTransactionGateway: gateway,
      );

      await expectLater(
        () => source.resolve(),
        throwsA(isA<TransactionPreparationException>()),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Utxo _utxo({
  required String txid,
  required int sat,
  int confirmations = 2,
  bool spendable = true,
}) => Utxo(
  txid: txid,
  vout: 0,
  amountSat: Satoshi(sat),
  confirmations: confirmations,
  address: 'bcrt1qtest',
  scriptPubKey: '0014abcd',
  type: AddressType.nativeSegwit,
  spendable: spendable,
);
