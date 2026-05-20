import 'dart:async';

import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/core/event_bus/events/transaction_event.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_action.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_bloc.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_event.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_state.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transaction/transaction.dart';

import 'fakes/fake_block_generation_gateway.dart';
import 'mocks/mock_block_generation_gateway.dart';

void main() {
  late FakeBlockGenerationGateway fakeGateway;
  late AppEventBus eventBus;
  late RegtestMiningBloc bloc;

  setUp(() {
    fakeGateway = FakeBlockGenerationGateway();
    eventBus = AppEventBus();
    bloc = RegtestMiningBloc(
      blockGenerationGateway: fakeGateway,
      eventBus: eventBus,
      walletId: 'wallet-1',
      addressResolver: (_) async => 'bcrt1qresolved',
    );
  });

  tearDown(() async {
    await bloc.close();
    eventBus.dispose();
  });

  // T1
  test('initial state is idle', () {
    expect(bloc.state.status, equals(RegtestMiningStatus.idle));
  });

  // T2
  test(
      'MineBlockRequested success emits processing then successful and fires BlockMined on event bus',
      () async {
    final busEvents = <dynamic>[];
    final sub = eventBus.stream.listen(busEvents.add);

    unawaited(
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<RegtestMiningState>()
              .having((s) => s.status, 'status', RegtestMiningStatus.processing),
          isA<RegtestMiningState>()
              .having((s) => s.status, 'status', RegtestMiningStatus.successful),
        ]),
      ),
    );

    bloc.add(const MineBlockRequested(toAddress: 'bcrt1qmine'));
    await bloc.stream
        .firstWhere((s) => s.status == RegtestMiningStatus.successful)
        .timeout(const Duration(seconds: 2));
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(fakeGateway.capturedAddress, equals('bcrt1qmine'));
    expect(busEvents, hasLength(1));
    expect(busEvents.first, isA<BlockMined>());
    expect((busEvents.first as BlockMined).walletId, equals('wallet-1'));
  });

  // T3
  test(
      'MineBlockRequested with TransactionException emits RegtestMiningFailedAction action and resets to idle',
      () async {
    fakeGateway.throwsValue = const TransactionBroadcastException();

    final actions = <RegtestMiningAction>[];
    final sub = bloc.actionStream.listen(actions.add);

    unawaited(
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<RegtestMiningState>()
              .having((s) => s.status, 'status', RegtestMiningStatus.processing),
          isA<RegtestMiningState>()
              .having((s) => s.status, 'status', RegtestMiningStatus.idle),
        ]),
      ),
    );

    bloc.add(const MineBlockRequested(toAddress: 'bcrt1qfail'));
    await bloc.stream
        .firstWhere((s) => s.status == RegtestMiningStatus.idle)
        .timeout(const Duration(seconds: 2));
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(actions, hasLength(1));
    expect(actions.first, isA<RegtestMiningFailedAction>());
  });

  // T4
  test(
      'MineBlockRequested with non-TransactionException emits RegtestMiningUnexpectedFailedAction and resets to idle',
      () async {
    fakeGateway.throwsValue = StateError('unexpected programmer error');

    final actions = <RegtestMiningAction>[];
    final sub = bloc.actionStream.listen(actions.add);

    unawaited(
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<RegtestMiningState>()
              .having((s) => s.status, 'status', RegtestMiningStatus.processing),
          isA<RegtestMiningState>()
              .having((s) => s.status, 'status', RegtestMiningStatus.idle),
        ]),
      ),
    );

    bloc.add(const MineBlockRequested(toAddress: 'bcrt1qerr'));
    await bloc.stream
        .firstWhere((s) => s.status == RegtestMiningStatus.idle)
        .timeout(const Duration(seconds: 2));
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(bloc.state.status, equals(RegtestMiningStatus.idle));
    expect(actions, hasLength(1));
    expect(actions.first, isA<RegtestMiningUnexpectedFailedAction>());
  });

  // T5 — interaction test: verifies gateway is called once per event via Mock
  test(
      'second MineBlockRequested while processing is queued — gateway called exactly twice sequentially',
      () async {
    final completer = Completer<void>();
    final mockGateway = MockBlockGenerationGateway();

    when(() => mockGateway.generateToAddress(any(), any())).thenAnswer(
      (_) async {
        await completer.future;

        return const ['blockhash_fake'];
      },
    );

    final slowBloc = RegtestMiningBloc(
      blockGenerationGateway: mockGateway,
      eventBus: eventBus,
      walletId: 'wallet-1',
      addressResolver: (_) async => 'bcrt1qresolved',
    );

    // Subscribe to all state emissions before dispatching events.
    final states = <RegtestMiningStatus>[];
    final stateSub = slowBloc.stream.listen((s) => states.add(s.status));

    slowBloc.add(const MineBlockRequested(toAddress: 'bcrt1qfirst'));
    await slowBloc.stream
        .firstWhere((s) => s.status == RegtestMiningStatus.processing)
        .timeout(const Duration(seconds: 2));

    // Dispatch second event while first is still in-flight.
    slowBloc.add(const MineBlockRequested(toAddress: 'bcrt1qsecond'));
    await Future<void>.delayed(Duration.zero);

    completer.complete();

    // Wait for two successful states (one per event).
    await Future.doWhile(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));

      return states.where((s) => s == RegtestMiningStatus.successful).length < 2;
    }).timeout(const Duration(seconds: 2));

    await stateSub.cancel();
    await slowBloc.close();

    verify(() => mockGateway.generateToAddress(any(), any())).called(2);
  });
}
