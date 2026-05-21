import 'dart:async';

import 'package:bitcoin_wallet/core/event_bus/app_event_bus.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_action.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_bloc.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_event.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_state.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

import 'fakes/error_capturing_observer.dart';
import 'fakes/fake_address_repository.dart';
import 'fakes/fake_broadcast_gateway.dart';
import 'fakes/fake_utxo_scan_gateway.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _walletId = 'wallet-test';
const _address = 'bcrt1qtest000';
const _fakeRawHex = 'aabbccdd';

Address _fakeAddress() => Address(
  value: _address,
  type: AddressType.nativeSegwit,
  walletId: _walletId,
  index: 0,
);

ScannedUtxo _fakeUtxo() => const ScannedUtxo(
  txid: 'utxo_txid_001',
  vout: 0,
  amountSat: Satoshi(100000),
  scriptPubKeyHex: '0014abcd',
  height: 1,
  address: _address,
);

SigningBloc _makeBloc({
  required FakeBroadcastGateway broadcastGateway,
  AppEventBus? eventBus,
}) => SigningBloc(
    addressRepository: FakeAddressRepository([_fakeAddress()]),
    utxoScanGateway: FakeUtxoScanGateway([_fakeUtxo()]),
    signTransaction: ({
      required walletId,
      required inputs,
      required outputs,
      required bech32Hrp,
    }) async => _fakeRawHex,
    broadcastGateway: broadcastGateway,
    eventBus: eventBus ?? AppEventBus(),
  );

Future<void> _triggerScan(SigningBloc bloc) async {
  bloc.add(const UtxoScanRequested(walletId: _walletId));
  await bloc.stream
      .firstWhere((s) => s.status == SigningStatus.scanned)
      .timeout(const Duration(seconds: 2));
}

Future<void> _triggerBroadcast(SigningBloc bloc) {
  bloc.add(const SignAndBroadcastRequested(
    walletId: _walletId,
    recipientAddress: 'bcrt1qrecipient',
    amountSat: 1000,
    bech32Hrp: 'bcrt',
  ));

  return Future<void>.value();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppEventBus eventBus;

  setUp(() {
    eventBus = AppEventBus();
  });

  tearDown(() {
    eventBus.dispose();
  });

  group('SigningBloc — getTransaction verification', () {
    // SBV1: happy path — both broadcast and getTransaction succeed
    test('SBV1: success path — state has broadcastedTx, txid, status=broadcasted', () async {
      final broadcastGateway = FakeBroadcastGateway()
        ..broadcastReturn = 'txid_001'
        ..getTransactionReturn = const BroadcastedTx(
          txid: 'txid_001',
          confirmations: 0,
          hex: 'deadbeef',
        );

      final bloc = _makeBloc(broadcastGateway: broadcastGateway, eventBus: eventBus);
      addTearDown(bloc.close);

      await _triggerScan(bloc);
      unawaited(_triggerBroadcast(bloc));

      final final_ = await bloc.stream
          .firstWhere((s) => s.status == SigningStatus.broadcasted)
          .timeout(const Duration(seconds: 2));

      expect(final_.txid, equals('txid_001'));
      expect(final_.broadcastedTx, isNotNull);
      expect(final_.broadcastedTx!.hex, equals('deadbeef'));
      expect(final_.status, equals(SigningStatus.broadcasted));
    });

    // SBV2: getTransaction throws TransactionException — txid preserved, broadcastedTx null
    test('SBV2: getTransaction TransactionException — txid preserved, status=broadcasted, action emitted', () async {
      final broadcastGateway = FakeBroadcastGateway()
        ..broadcastReturn = 'txid_002'
        ..getTransactionError = const TransactionFetchException();

      final bloc = _makeBloc(broadcastGateway: broadcastGateway, eventBus: eventBus);
      addTearDown(bloc.close);

      final actions = <SigningAction>[];
      final sub = bloc.actionStream.listen(actions.add);

      await _triggerScan(bloc);
      unawaited(_triggerBroadcast(bloc));

      final final_ = await bloc.stream
          .firstWhere((s) => s.status == SigningStatus.broadcasted)
          .timeout(const Duration(seconds: 2));

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(final_.txid, equals('txid_002'));
      expect(final_.broadcastedTx, isNull);
      expect(final_.status, equals(SigningStatus.broadcasted));
      expect(actions.whereType<SigningVerificationFailedAction>(), hasLength(1));
    });

    // SBV3: getTransaction throws unexpected Exception — addError invoked, action emitted
    test('SBV3: getTransaction unexpected Exception — addError invoked, txid preserved', () async {
      final broadcastGateway = FakeBroadcastGateway()
        ..broadcastReturn = 'txid_003'
        ..getTransactionError = Exception('network timeout');

      // Capture addError via Bloc.observer.
      final observer = ErrorCapturingObserver();
      final prevObserver = Bloc.observer;
      Bloc.observer = observer;
      addTearDown(() => Bloc.observer = prevObserver);

      final bloc = _makeBloc(broadcastGateway: broadcastGateway, eventBus: eventBus);
      addTearDown(bloc.close);

      final actions = <SigningAction>[];
      final sub = bloc.actionStream.listen(actions.add);

      await _triggerScan(bloc);
      unawaited(_triggerBroadcast(bloc));

      final final_ = await bloc.stream
          .firstWhere((s) => s.status == SigningStatus.broadcasted)
          .timeout(const Duration(seconds: 2));

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(final_.txid, equals('txid_003'));
      expect(final_.broadcastedTx, isNull);
      expect(actions.whereType<SigningVerificationFailedAction>(), hasLength(1));
      expect(observer.errors, hasLength(1));
    });
  });
}

