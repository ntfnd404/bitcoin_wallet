import 'package:rpc_client/rpc_client.dart';
import 'package:test/test.dart';
import 'package:transaction/transaction.dart';

import 'fakes/fake_broadcast_gateway.dart';

void main() {
  group('BroadcastTransactionUseCase', () {
    late FakeBroadcastGateway gateway;
    late BroadcastTransactionUseCase useCase;

    setUp(() {
      gateway = FakeBroadcastGateway();
      useCase = BroadcastTransactionUseCase(dataSource: gateway);
    });

    group('broadcast', () {
      test('returns txid on success', () async {
        final txid = await useCase.broadcast('raw_hex');

        expect(txid, 'txid_abc123');
      });

      test('RpcException translates to TransactionBroadcastException', () async {
        gateway.broadcastThrows = const RpcException('sendrawtransaction', {'code': -22, 'message': 'TX decode failed'});

        await expectLater(
          useCase.broadcast('raw_hex'),
          throwsA(isA<TransactionBroadcastException>()),
        );
      });

      test('StateError propagates — programmer errors are not wrapped', () async {
        gateway.broadcastThrows = StateError('programmer bug');

        await expectLater(
          useCase.broadcast('raw_hex'),
          throwsA(isA<StateError>()),
        );
      });

      test('ArgumentError propagates', () async {
        gateway.broadcastThrows = ArgumentError('bad input');

        await expectLater(
          useCase.broadcast('raw_hex'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('getTransaction', () {
      test('returns BroadcastedTx on success', () async {
        final tx = await useCase.getTransaction('txid_abc123');

        expect(tx.txid, 'txid_abc123');
        expect(tx.confirmations, 1);
      });

      test('RpcException translates to TransactionFetchException', () async {
        gateway.getTransactionThrows = const RpcException('getrawtransaction', {'code': -5, 'message': 'No such mempool or blockchain transaction'});

        await expectLater(
          useCase.getTransaction('txid'),
          throwsA(isA<TransactionFetchException>()),
        );
      });

      test('TypeError propagates', () async {
        gateway.getTransactionThrows = TypeError();

        await expectLater(
          useCase.getTransaction('txid'),
          throwsA(isA<TypeError>()),
        );
      });
    });
  });
}
