import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/src/application/source/node_auto_utxo_source.dart';
import 'package:transaction/transaction.dart';

import '../fakes/fake_node_transaction_gateway.dart';
import '../fakes/fake_utxo_repository.dart';

void main() {
  late FakeUtxoRepository repo;
  late FakeNodeTransactionGateway gateway;

  setUp(() {
    repo = FakeUtxoRepository();
    gateway = FakeNodeTransactionGateway();
  });

  group('NodeAutoUtxoSource', () {
    test('drops non-spendable UTXOs before mapping', () async {
      repo.utxos = [
        _utxo(txid: 'a', sat: 50000),
        _utxo(txid: 'b', sat: 100, spendable: false),
      ];

      final source = NodeAutoUtxoSource(
        walletName: 'w',
        utxoRepository: repo,
        nodeTransactionGateway: gateway,
      );

      final result = await source.resolve();

      expect(result.candidates, hasLength(1));
      expect(result.candidates.first.txid, equals('a'));
    });

    test('maps Utxo to CoinCandidate field-for-field', () async {
      repo.utxos = [_utxo(txid: 'a', sat: 12345, confirmations: 7)];

      final source = NodeAutoUtxoSource(
        walletName: 'w',
        utxoRepository: repo,
        nodeTransactionGateway: gateway,
      );

      final result = await source.resolve();
      final c = result.candidates.single;

      expect(c.txid, equals('a'));
      expect(c.vout, equals(0));
      expect(c.amountSat, equals(const Satoshi(12345)));
      expect(c.age, equals(7));
      expect(c.scriptType, equals(AddressType.nativeSegwit));
      expect(c.scriptPubKeyHex, equals('0014abcd'));
      expect(c.confirmations, equals(7));
    });

    test('changeAddress comes from gateway.getNewAddress', () async {
      repo.utxos = const [];
      gateway.newAddressResult = 'bcrt1qchange-from-node';

      final source = NodeAutoUtxoSource(
        walletName: 'w',
        utxoRepository: repo,
        nodeTransactionGateway: gateway,
      );

      final result = await source.resolve();

      expect(result.changeAddress, equals('bcrt1qchange-from-node'));
    });

    test('signingContext is NodeSigningContext', () async {
      repo.utxos = const [];

      final source = NodeAutoUtxoSource(
        walletName: 'w',
        utxoRepository: repo,
        nodeTransactionGateway: gateway,
      );

      final result = await source.resolve();

      expect(result.signingContext, isA<NodeSigningContext>());
    });

    test('wraps generic infra exception into TransactionPreparationException', () async {
      repo.throwOnGet = Exception('boom');

      final source = NodeAutoUtxoSource(
        walletName: 'w',
        utxoRepository: repo,
        nodeTransactionGateway: gateway,
      );

      expect(
        source.resolve,
        throwsA(isA<TransactionPreparationException>()),
      );
    });

    test('rethrows TransactionException unchanged', () async {
      repo.throwOnGet = const TransactionFetchException();

      final source = NodeAutoUtxoSource(
        walletName: 'w',
        utxoRepository: repo,
        nodeTransactionGateway: gateway,
      );

      expect(
        source.resolve,
        throwsA(isA<TransactionFetchException>()),
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
