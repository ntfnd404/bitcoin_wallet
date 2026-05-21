import 'dart:async';

import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_action.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_bloc.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_event.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_state.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

import 'fakes/fake_broadcast_gateway.dart';
import 'fakes/fake_node_transaction_gateway.dart';
import 'fakes/fake_utxo_repository.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Utxo _utxo() => const Utxo(
  txid: 'utxo_txid',
  vout: 0,
  amountSat: Satoshi(100000),
  confirmations: 1,
  address: 'bcrt1qtest',
  scriptPubKey: '0014abcd',
  type: AddressType.nativeSegwit,
  spendable: true,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeBroadcastGateway fakeBroadcast;
  late AppEventBus eventBus;
  late OpReturnBloc bloc;

  setUp(() {
    fakeBroadcast = FakeBroadcastGateway();
    eventBus = AppEventBus();
    final useCase = SendOpReturnUseCase(
      utxoRepository: FakeUtxoRepository([_utxo()]),
      nodeDataSource: FakeNodeTransactionGateway(),
      broadcastDataSource: fakeBroadcast,
      feeEstimator: const P2wpkhFeeEstimator(),
    );
    bloc = OpReturnBloc(
      useCase: useCase,
      eventBus: eventBus,
      walletId: 'wallet-1',
      walletName: 'test-wallet',
    );
  });

  tearDown(() async {
    await bloc.close();
    eventBus.dispose();
  });

  group('OpReturnBloc', () {
    // OB1
    test('OB1: valid text updates byteCount, isValid, and hexPreview', () async {
      bloc.add(const OpReturnDataChanged('Hi'));
      final state = await bloc.stream.first.timeout(const Duration(seconds: 1));

      expect(state.byteCount, equals(2));
      expect(state.isValid, isTrue);
      expect(state.hexPreview, isNotEmpty);
    });

    // OB2
    test('OB2: text > 80 UTF-8 bytes marks isValid = false and clears preview', () async {
      bloc.add(OpReturnDataChanged('a' * 81));
      final state = await bloc.stream.first.timeout(const Duration(seconds: 1));

      expect(state.byteCount, equals(81));
      expect(state.isValid, isFalse);
      expect(state.hexPreview, isEmpty);
    });

    // OB3
    test('OB3: broadcast success emits OpReturnBroadcastedAction with txid', () async {
      fakeBroadcast.result = 'txid_abc';

      bloc.add(const OpReturnDataChanged('Hello'));
      await bloc.stream.firstWhere((s) => s.isValid).timeout(const Duration(seconds: 2));

      final actions = <OpReturnAction>[];
      final sub = bloc.actionStream.listen(actions.add);

      unawaited(
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<OpReturnState>().having((s) => s.status, 'processing', OpReturnStatus.processing),
            isA<OpReturnState>().having((s) => s.status, 'idle', OpReturnStatus.idle),
          ]),
        ),
      );

      bloc.add(const OpReturnBroadcastRequested());
      await bloc.stream
          .firstWhere((s) => s.status == OpReturnStatus.idle)
          .timeout(const Duration(seconds: 2));
      await sub.cancel();

      expect(actions, hasLength(1));
      expect(actions.first, isA<OpReturnBroadcastedAction>());
      expect((actions.first as OpReturnBroadcastedAction).txid, equals('txid_abc'));
    });

    // OB4
    test('OB4: TransactionBroadcastException emits OpReturnBroadcastFailedAction', () async {
      fakeBroadcast.throwsValue = const TransactionBroadcastException();

      bloc.add(const OpReturnDataChanged('test'));
      await bloc.stream.firstWhere((s) => s.isValid).timeout(const Duration(seconds: 2));

      final actions = <OpReturnAction>[];
      final sub = bloc.actionStream.listen(actions.add);

      bloc.add(const OpReturnBroadcastRequested());
      await bloc.stream
          .firstWhere((s) => s.status == OpReturnStatus.idle)
          .timeout(const Duration(seconds: 2));
      await sub.cancel();

      expect(actions.first, isA<OpReturnBroadcastFailedAction>());
    });

    // OB5
    test('OB5: single ASCII char produces correct hexPreview', () async {
      bloc.add(const OpReturnDataChanged('A'));
      final state = await bloc.stream.first.timeout(const Duration(seconds: 1));

      // 'A' = 0x41 → direct push: 6a 01 41
      expect(state.hexPreview, equals('6a0141'));
    });
  });
}
