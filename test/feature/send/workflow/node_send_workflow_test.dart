import 'package:flutter_test/flutter_test.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

import 'fakes/fake_address_repository.dart';
import 'fakes/fake_broadcast_gateway.dart';
import 'fakes/fake_coin_selector.dart';
import 'fakes/fake_node_transaction_gateway.dart';
import 'fakes/fake_transaction_signer.dart';
import 'fakes/fake_utxo_repository.dart';
import 'fakes/fake_utxo_scan_gateway.dart';

void main() {
  late FakeUtxoRepository fakeUtxoRepo;
  late FakeNodeTransactionGateway fakeNodeGateway;
  late FakeBroadcastGateway fakeBroadcast;
  late FakeCoinSelector fakeCoinSelector;
  late NodeSendWorkflow workflow;

  const walletName = 'test_wallet';
  const targetSat = Satoshi(50000);
  const feeRate = 10;

  setUp(() {
    fakeUtxoRepo = FakeUtxoRepository();
    fakeNodeGateway = FakeNodeTransactionGateway();
    fakeBroadcast = FakeBroadcastGateway();
    fakeCoinSelector = FakeCoinSelector(name: 'fifo');

    fakeUtxoRepo.utxos = [
      const Utxo(
        txid: 'abc123',
        vout: 0,
        amountSat: Satoshi(100000),
        confirmations: 3,
        address: 'bcrt1qinput',
        scriptPubKey: '0014aabbcc',
        type: AddressType.nativeSegwit,
        spendable: true,
      ),
    ];

    final prepareUseCase = PrepareNodeSendUseCase(
      utxoRepository: fakeUtxoRepo,
      nodeDataSource: fakeNodeGateway,
      selectors: [fakeCoinSelector],
      feeEstimator: const P2wpkhFeeEstimator(),
    );

    final sendUseCase = SendNodeTransactionUseCase(
      nodeDataSource: fakeNodeGateway,
      broadcastDataSource: fakeBroadcast,
    );

    workflow = NodeSendWorkflow(
      prepare: prepareUseCase,
      send: sendUseCase,
      walletName: walletName,
    );
  });

  group('NodeSendWorkflow', () {
    // T1
    test('prepare returns NodeSendResult with correct strategies and changeAddress', () async {
      final preparation = await workflow.prepare(
        targetSat: targetSat,
        feeRateSatPerVbyte: feeRate,
      );

      expect(preparation.strategies, isNotEmpty);
      expect(preparation.strategies.containsKey('fifo'), isTrue);
      expect(preparation.changeAddress, equals(fakeNodeGateway.newAddressResult));
    });

    // T2
    test('prepare throws TransactionException when use case throws', () async {
      fakeNodeGateway.newAddressThrows = const TransactionPreparationException();

      await expectLater(
        workflow.prepare(targetSat: targetSat, feeRateSatPerVbyte: feeRate),
        throwsA(isA<TransactionException>()),
      );
    });

    // T3
    test('confirm calls SendNodeTransactionUseCase with captured walletName', () async {
      final preparation = await workflow.prepare(
        targetSat: targetSat,
        feeRateSatPerVbyte: feeRate,
      );

      await workflow.confirm(
        preparation: preparation,
        strategyName: 'fifo',
        recipientAddress: 'bcrt1qrecipient',
        amountSat: targetSat,
      );

      expect(fakeNodeGateway.capturedSignWalletName, equals(walletName));
    });

    // T4
    test('confirm throws ArgumentError when preparation is wrong type', () async {
      final hdPreparation = await _buildHdPreparation(
        fakeBroadcast: fakeBroadcast,
        fakeCoinSelector: fakeCoinSelector,
      );

      await expectLater(
        workflow.confirm(
          preparation: hdPreparation,
          strategyName: 'fifo',
          recipientAddress: 'bcrt1qrecipient',
          amountSat: targetSat,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

Future<SendPreparation> _buildHdPreparation({
  required FakeBroadcastGateway fakeBroadcast,
  required FakeCoinSelector fakeCoinSelector,
}) {
  final fakeAddressRepo = FakeAddressRepository();
  fakeAddressRepo.addresses = [
    Address(
      value: 'bcrt1qhd',
      walletId: 'hd_wallet',
      index: 0,
      type: AddressType.nativeSegwit,
    ),
  ];

  final fakeUtxoScan = FakeUtxoScanGateway();
  fakeUtxoScan.scanResult = [
    const ScannedUtxo(
      txid: 'hdtxid',
      vout: 0,
      amountSat: Satoshi(100000),
      scriptPubKeyHex: '0014aabbcc',
      height: 1,
      address: 'bcrt1qhd',
    ),
  ];

  final hdWorkflow = HdSendWorkflow(
    prepare: PrepareHdSendUseCase(
      addressRepository: fakeAddressRepo,
      utxoScanDataSource: fakeUtxoScan,
      selectors: [fakeCoinSelector],
      feeEstimator: const P2wpkhFeeEstimator(),
    ),
    send: SendHdTransactionUseCase(
      signer: FakeTransactionSigner(),
      broadcastDataSource: fakeBroadcast,
    ),
    walletId: 'hd_wallet',
    bech32Hrp: 'bcrt',
  );

  return hdWorkflow.prepare(
    targetSat: const Satoshi(50000),
    feeRateSatPerVbyte: 10,
  );
}
