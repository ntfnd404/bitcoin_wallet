import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_picker/utxo_picker_action.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_picker/utxo_picker_bloc.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_picker/utxo_picker_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

import 'fakes/fake_fee_estimator.dart';
import 'fakes/fake_utxo_repository.dart';

void main() {
  group('UtxoPickerBloc', () {
    late UtxoPickerBloc bloc;

    tearDown(() => bloc.close());

    // UP1: load success + spendable filter
    test('UP1: load filters non-spendable UTXOs', () async {
      final repo = FakeUtxoRepository()
        ..utxos = [_utxo(), _utxo(txid: 'tx2', spendable: false)];
      bloc = _makeBloc(repo: repo);

      bloc.add(const UtxoPickerLoaded(walletName: 'test'));
      final state = await bloc.stream
          .firstWhere((s) => s.status == FetchStatus.idle && s.utxos.isNotEmpty)
          .timeout(const Duration(seconds: 2));

      expect(state.utxos, hasLength(1));
      expect(state.utxos.first.txid, equals('tx1'));
    });

    // UP2: load failure emits action
    test('UP2: repository error emits UtxoPickerLoadFailedAction', () async {
      final repo = FakeUtxoRepository()
        ..throwOnGet = const TransactionFetchException();
      bloc = _makeBloc(repo: repo);

      final actions = <UtxoPickerAction>[];
      final sub = bloc.actionStream.listen(actions.add);

      bloc.add(const UtxoPickerLoaded(walletName: 'test'));
      await bloc.stream
          .firstWhere((s) => s.status == FetchStatus.idle)
          .timeout(const Duration(seconds: 2));
      await sub.cancel();

      expect(actions, hasLength(1));
      expect(actions.first, isA<UtxoPickerLoadFailedAction>());
    });

    // UP3: toggle adds and removes key
    test('UP3: toggle adds then removes selection key', () async {
      final repo = FakeUtxoRepository()..utxos = [_utxo()];
      bloc = _makeBloc(repo: repo);

      bloc.add(const UtxoPickerLoaded(walletName: 'test'));
      await bloc.stream
          .firstWhere((s) => s.utxos.isNotEmpty)
          .timeout(const Duration(seconds: 2));

      bloc.add(const UtxoPickerSelectionToggled(txid: 'tx1', vout: 0));
      final selected = await bloc.stream.first.timeout(const Duration(seconds: 1));
      expect(selected.selectedKeys, contains('tx1:0'));
      expect(selected.canProceed, isTrue);

      bloc.add(const UtxoPickerSelectionToggled(txid: 'tx1', vout: 0));
      final deselected = await bloc.stream.first.timeout(const Duration(seconds: 1));
      expect(deselected.selectedKeys, isEmpty);
      expect(deselected.canProceed, isFalse);
    });

    // UP4: fee-rate change updates totals
    test('UP4: fee-rate change updates estimatedFeeSat', () async {
      final repo = FakeUtxoRepository()..utxos = [_utxo()];
      final feeEstimator = FakeFeeEstimator()..estimateResult = const Satoshi(300);
      bloc = _makeBloc(repo: repo, fee: feeEstimator);

      bloc.add(const UtxoPickerLoaded(walletName: 'test'));
      await bloc.stream.firstWhere((s) => s.utxos.isNotEmpty).timeout(const Duration(seconds: 2));
      bloc.add(const UtxoPickerSelectionToggled(txid: 'tx1', vout: 0));
      await bloc.stream.first.timeout(const Duration(seconds: 1));

      feeEstimator.estimateResult = const Satoshi(500);
      bloc.add(const UtxoPickerFeeRateChanged(feeRateSatPerVbyte: 5));
      final state = await bloc.stream.first.timeout(const Duration(seconds: 1));

      expect(state.estimatedFeeSat.value, equals(500));
    });

    // UP5: canProceed boundary
    test('UP5: canProceed false when empty, true when ≥1 selected', () async {
      final repo = FakeUtxoRepository()..utxos = [_utxo()];
      bloc = _makeBloc(repo: repo);

      bloc.add(const UtxoPickerLoaded(walletName: 'test'));
      await bloc.stream.firstWhere((s) => s.utxos.isNotEmpty).timeout(const Duration(seconds: 2));

      expect(bloc.state.canProceed, isFalse);

      bloc.add(const UtxoPickerSelectionToggled(txid: 'tx1', vout: 0));
      await bloc.stream.first.timeout(const Duration(seconds: 1));

      expect(bloc.state.canProceed, isTrue);
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Utxo _utxo({
  String txid = 'tx1',
  int vout = 0,
  int amountSat = 50000,
  bool spendable = true,
}) => Utxo(
  txid: txid,
  vout: vout,
  amountSat: Satoshi(amountSat),
  confirmations: 1,
  address: 'bcrt1qtest',
  scriptPubKey: '0014abcd',
  type: AddressType.nativeSegwit,
  spendable: spendable,
);

UtxoPickerBloc _makeBloc({
  FakeUtxoRepository? repo,
  FakeFeeEstimator? fee,
}) => UtxoPickerBloc(
  utxoRepository: repo ?? FakeUtxoRepository(),
  feeEstimator: fee ?? FakeFeeEstimator(),
);
