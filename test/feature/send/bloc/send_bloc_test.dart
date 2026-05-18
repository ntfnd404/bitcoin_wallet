import 'dart:async';

import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/core/event_bus/events/transaction_event.dart';
import 'package:bitcoin_wallet/feature/send/bloc/coin_selection_mode.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_action.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_bloc.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_event.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_state.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

import 'fakes/fake_send_workflow.dart';

// ---------------------------------------------------------------------------
// Test data factories
// ---------------------------------------------------------------------------

CoinSelectionResult _fakeCoinResult({int fee = 1000, int change = 49000}) =>
    CoinSelectionResult(
      inputs: const [
        CoinCandidate(txid: 'abc', vout: 0, amountSat: Satoshi(100000), age: 1),
      ],
      totalInputSat: const Satoshi(100000),
      changeSat: Satoshi(change),
      feeSat: Satoshi(fee),
    );

/// Builds a test [SendPreparation] for BLoC tests.
///
/// Uses [SendPreparation.forTest] to avoid depending on internal subtypes
/// ([NodeSendResult]/[HdSendResult]) from the test layer.
SendPreparation _fakePrep([String strategyName = 'fifo']) =>
    SendPreparation.forTest(
      strategies: {strategyName: _fakeCoinResult()},
      changeAddress: 'bcrt1qchange',
    );

/// Multi-strategy prep where 'min_change' has the lowest fee, so it is the
/// expected recommended strategy.
SendPreparation _fakeMultiPrep() => SendPreparation.forTest(
  strategies: {
    'fifo': _fakeCoinResult(fee: 2000, change: 48000),
    'lifo': _fakeCoinResult(fee: 1500, change: 48500),
    'min_change': _fakeCoinResult(),
  },
  changeAddress: 'bcrt1qchange',
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeSendWorkflow fakeWorkflow;
  late AppEventBus eventBus;
  late SendBloc bloc;

  const walletId = 'wallet_id_001';

  setUp(() {
    fakeWorkflow = FakeSendWorkflow();
    eventBus = AppEventBus();
    bloc = SendBloc(
      workflow: fakeWorkflow,
      eventBus: eventBus,
      walletId: walletId,
    );
  });

  tearDown(() async {
    await bloc.close();
    eventBus.dispose();
  });

  group('SendBloc — SendFormSubmitted', () {
    // B1
    test('emits preparing → awaitingConfirmation on successful prepare', () async {
      final prep = _fakePrep();
      fakeWorkflow.prepareResult = prep;

      unawaited(
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SendState>().having((s) => s.status, 'status', SendStatus.preparing),
            isA<SendState>().having((s) => s.status, 'status', SendStatus.awaitingConfirmation),
          ]),
        ),
      );

      bloc.add(
        const SendFormSubmitted(
          recipientAddress: 'bcrt1qrecipient',
          amountSat: 50000,
          feeRateSatPerVbyte: 10,
        ),
      );

      await bloc.stream
          .firstWhere((s) => s.status == SendStatus.awaitingConfirmation)
          .timeout(const Duration(seconds: 2));
    });

    // B2
    test('state carries preparation, strategies, recipientAddress, amountSat', () async {
      final prep = _fakePrep();
      fakeWorkflow.prepareResult = prep;

      bloc.add(
        const SendFormSubmitted(
          recipientAddress: 'bcrt1qrecipient',
          amountSat: 50000,
          feeRateSatPerVbyte: 10,
        ),
      );

      final confirmed = await bloc.stream
          .firstWhere((s) => s.status == SendStatus.awaitingConfirmation)
          .timeout(const Duration(seconds: 2));

      expect(confirmed.preparation, same(prep));
      expect(confirmed.strategies, equals(prep.strategies));
      expect(confirmed.recipientAddress, equals('bcrt1qrecipient'));
      expect(confirmed.amountSat, equals(50000));
      expect(confirmed.selectedStrategy, equals('fifo'));
      expect(confirmed.changeAddress, equals('bcrt1qchange'));
    });

    // B3
    test('emits SendInsufficientFundsAction action and error status when strategies empty', () async {
      fakeWorkflow.prepareResult = SendPreparation.forTest(
        strategies: {},
        changeAddress: 'bcrt1qchange',
      );

      final actions = <SendAction>[];
      final sub = bloc.actionStream.listen(actions.add);

      bloc.add(
        const SendFormSubmitted(
          recipientAddress: 'bcrt1qrecipient',
          amountSat: 50000,
          feeRateSatPerVbyte: 10,
        ),
      );

      await bloc.stream
          .firstWhere((s) => s.status == SendStatus.idle)
          .timeout(const Duration(seconds: 2));

      await sub.cancel();
      expect(actions, hasLength(1));
      expect(actions.first, isA<SendInsufficientFundsAction>());
    });

    // B4
    test('emits SendFailedAction action and error status on TransactionException', () async {
      fakeWorkflow.prepareThrows = const TransactionPreparationException();

      final actions = <SendAction>[];
      final sub = bloc.actionStream.listen(actions.add);

      bloc.add(
        const SendFormSubmitted(
          recipientAddress: 'bcrt1qrecipient',
          amountSat: 50000,
          feeRateSatPerVbyte: 10,
        ),
      );

      await bloc.stream
          .firstWhere((s) => s.status == SendStatus.idle)
          .timeout(const Duration(seconds: 2));

      await sub.cancel();
      expect(actions, hasLength(1));
      expect(actions.first, isA<SendFailedAction>());
    });
  });

  group('SendBloc — SendStrategySelected', () {
    // B5
    test('updates selectedStrategy and switches mode to manual', () async {
      fakeWorkflow.prepareResult = _fakeMultiPrep();

      bloc.add(
        const SendFormSubmitted(
          recipientAddress: 'bcrt1qrecipient',
          amountSat: 50000,
          feeRateSatPerVbyte: 10,
        ),
      );
      await bloc.stream
          .firstWhere((s) => s.status == SendStatus.awaitingConfirmation)
          .timeout(const Duration(seconds: 2));

      bloc.add(const SendStrategySelected(strategyName: 'lifo'));

      final next = await bloc.stream.first.timeout(const Duration(seconds: 2));
      expect(next.selectedStrategy, equals('lifo'));
      expect(next.selectionMode, equals(CoinSelectionMode.manual));
      expect(next.status, equals(SendStatus.awaitingConfirmation));
    });

    // B5b
    test('ignores SendStrategySelected with unknown strategy name', () async {
      fakeWorkflow.prepareResult = _fakeMultiPrep();

      bloc.add(
        const SendFormSubmitted(
          recipientAddress: 'bcrt1qrecipient',
          amountSat: 50000,
          feeRateSatPerVbyte: 10,
        ),
      );
      final initial = await bloc.stream
          .firstWhere((s) => s.status == SendStatus.awaitingConfirmation)
          .timeout(const Duration(seconds: 2));

      bloc.add(const SendStrategySelected(strategyName: 'nonexistent'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.selectedStrategy, equals(initial.selectedStrategy));
      expect(bloc.state.selectionMode, equals(CoinSelectionMode.auto));
    });
  });

  group('SendBloc — Auto/Manual selection mode', () {
    Future<void> prepareMulti() async {
      fakeWorkflow.prepareResult = _fakeMultiPrep();
      bloc.add(
        const SendFormSubmitted(
          recipientAddress: 'bcrt1qrecipient',
          amountSat: 50000,
          feeRateSatPerVbyte: 10,
        ),
      );
      await bloc.stream
          .firstWhere((s) => s.status == SendStatus.awaitingConfirmation)
          .timeout(const Duration(seconds: 2));
    }

    // BA1
    test('after prepare, selectionMode is auto and selectedStrategy is recommended',
        () async {
      await prepareMulti();

      expect(bloc.state.selectionMode, equals(CoinSelectionMode.auto));
      expect(bloc.state.selectedStrategy, equals('min_change'));
    });

    // BA2
    test('SendSelectionModeChanged(auto) recalculates recommended', () async {
      await prepareMulti();

      bloc.add(const SendStrategySelected(strategyName: 'fifo'));
      await bloc.stream
          .firstWhere((s) => s.selectionMode == CoinSelectionMode.manual)
          .timeout(const Duration(seconds: 2));
      expect(bloc.state.selectedStrategy, equals('fifo'));

      bloc.add(const SendSelectionModeChanged(mode: CoinSelectionMode.auto));
      await bloc.stream
          .firstWhere((s) => s.selectionMode == CoinSelectionMode.auto)
          .timeout(const Duration(seconds: 2));

      expect(bloc.state.selectedStrategy, equals('min_change'));
    });

    // BA3
    test('SendSelectionModeChanged(manual) preserves current selectedStrategy',
        () async {
      await prepareMulti();
      final before = bloc.state.selectedStrategy;

      bloc.add(const SendSelectionModeChanged(mode: CoinSelectionMode.manual));
      await bloc.stream
          .firstWhere((s) => s.selectionMode == CoinSelectionMode.manual)
          .timeout(const Duration(seconds: 2));

      expect(bloc.state.selectedStrategy, equals(before));
      expect(bloc.state.selectionMode, equals(CoinSelectionMode.manual));
    });
  });

  group('SendBloc — SendConfirmed', () {
    Future<void> prepareBloc() async {
      fakeWorkflow.prepareResult = _fakePrep();
      bloc.add(
        const SendFormSubmitted(
          recipientAddress: 'bcrt1qrecipient',
          amountSat: 50000,
          feeRateSatPerVbyte: 10,
        ),
      );
      await bloc.stream
          .firstWhere((s) => s.status == SendStatus.awaitingConfirmation)
          .timeout(const Duration(seconds: 2));
    }

    // B6
    test('emits sending → sent and fires TransactionBroadcasted on success', () async {
      await prepareBloc();
      fakeWorkflow.confirmResult = 'txid_broadcast_001';

      final events = <dynamic>[];
      final sub = eventBus.stream.listen(events.add);

      unawaited(
        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<SendState>().having((s) => s.status, 'status', SendStatus.sending),
            isA<SendState>().having((s) => s.status, 'status', SendStatus.successful),
          ]),
        ),
      );

      bloc.add(const SendConfirmed());
      await bloc.stream
          .firstWhere((s) => s.status == SendStatus.successful)
          .timeout(const Duration(seconds: 2));
      // Yield to the microtask queue so the eventBus.emit call that follows
      // the bloc state emit in _onConfirmed has a chance to deliver to listeners.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events, hasLength(1));
      expect(events.first, isA<TransactionBroadcasted>());
      expect((events.first as TransactionBroadcasted).txid, equals('txid_broadcast_001'));
    });

    // B7
    test('confirm passes preparation from state back to workflow unchanged', () async {
      await prepareBloc();
      fakeWorkflow.confirmResult = 'txid_002';

      bloc.add(const SendConfirmed());
      await bloc.stream
          .firstWhere((s) => s.status == SendStatus.successful)
          .timeout(const Duration(seconds: 2));

      expect(fakeWorkflow.capturedConfirmStrategyName, equals('fifo'));
      expect(fakeWorkflow.capturedConfirmRecipientAddress, equals('bcrt1qrecipient'));
      expect(fakeWorkflow.capturedConfirmAmountSat, equals(const Satoshi(50000)));
    });

    // B8
    test('emits SendFailedAction action and error status on TransactionException from confirm', () async {
      await prepareBloc();
      fakeWorkflow.confirmThrows = const TransactionBroadcastException();

      final actions = <SendAction>[];
      final sub = bloc.actionStream.listen(actions.add);

      bloc.add(const SendConfirmed());
      await bloc.stream
          .firstWhere((s) => s.status == SendStatus.idle)
          .timeout(const Duration(seconds: 2));

      await sub.cancel();
      expect(actions, hasLength(1));
      expect(actions.first, isA<SendFailedAction>());
    });

    // B9
    test('returns early without emitting when state has no preparation', () async {
      // No prepare step — state.preparation is null.
      final states = <SendState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const SendConfirmed());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await sub.cancel();

      expect(states, isEmpty);
    });
  });

}
