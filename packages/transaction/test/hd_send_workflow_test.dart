import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
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
  late FakeAddressRepository fakeAddressRepo;
  late FakeUtxoScanGateway fakeUtxoScan;
  late FakeBroadcastGateway fakeBroadcast;
  late FakeCoinSelector fakeCoinSelector;
  late FakeTransactionSigner fakeSigner;
  late HdSendWorkflow workflow;

  const walletId = 'hd_wallet_id';
  const bech32Hrp = 'bcrt';
  const targetSat = Satoshi(50000);
  const feeRate = 10;

  setUp(() {
    fakeAddressRepo = FakeAddressRepository();
    fakeUtxoScan = FakeUtxoScanGateway();
    fakeBroadcast = FakeBroadcastGateway();
    fakeCoinSelector = FakeCoinSelector(name: 'fifo');
    fakeSigner = FakeTransactionSigner();

    fakeAddressRepo.addresses = [
      Address(
        value: 'bcrt1qhdinput',
        walletId: walletId,
        index: 0,
        type: AddressType.nativeSegwit,
      ),
    ];

    fakeUtxoScan.scanResult = [
      const ScannedUtxo(
        txid: 'hdtxid123',
        vout: 0,
        amountSat: Satoshi(100000),
        scriptPubKeyHex: '0014aabbcc',
        height: 1,
        address: 'bcrt1qhdinput',
      ),
    ];

    final prepareUseCase = PrepareHdSendUseCase(
      addressRepository: fakeAddressRepo,
      utxoScanDataSource: fakeUtxoScan,
      selectors: [fakeCoinSelector],
      feeEstimator: const P2wpkhFeeEstimator(),
    );

    final sendUseCase = SendHdTransactionUseCase(
      signer: fakeSigner,
      broadcastDataSource: fakeBroadcast,
    );

    workflow = HdSendWorkflow(
      prepare: prepareUseCase,
      send: sendUseCase,
      walletId: walletId,
      bech32Hrp: bech32Hrp,
    );
  });

  group('HdSendWorkflow', () {
    // T1
    test('prepare returns HdSendResult with correct strategies and changeAddress', () async {
      final preparation = await workflow.prepare(
        targetSat: targetSat,
        feeRateSatPerVbyte: feeRate,
      );

      expect(preparation.strategies, isNotEmpty);
      expect(preparation.strategies.any((e) => e.name == 'fifo'), isTrue);
      expect(preparation.changeAddress, isNotEmpty);
    });

    // T2
    test('prepare throws TransactionException when use case throws', () async {
      fakeUtxoScan.throwOnScan = const TransactionPreparationException();

      await expectLater(
        workflow.prepare(targetSat: targetSat, feeRateSatPerVbyte: feeRate),
        throwsA(isA<TransactionException>()),
      );
    });

    // T3
    test('confirm calls SendHdTransactionUseCase with captured walletId and bech32Hrp', () async {
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

      expect(fakeSigner.capturedWalletId, equals(walletId));
      expect(fakeSigner.capturedBech32Hrp, equals(bech32Hrp));
    });

    // T4
    test('confirm throws ArgumentError when preparation is wrong type', () async {
      final nodePreparation = await _buildNodePreparation(
        fakeCoinSelector: fakeCoinSelector,
      );

      await expectLater(
        workflow.confirm(
          preparation: nodePreparation,
          strategyName: 'fifo',
          recipientAddress: 'bcrt1qrecipient',
          amountSat: targetSat,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

Future<SendPreparation> _buildNodePreparation({
  required FakeCoinSelector fakeCoinSelector,
}) {
  final fakeUtxoRepo = FakeUtxoRepository();
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

  final fakeNodeGateway = FakeNodeTransactionGateway();
  final fakeBroadcast = FakeBroadcastGateway();

  final nodeWorkflow = NodeSendWorkflow(
    prepare: PrepareNodeSendUseCase(
      utxoRepository: fakeUtxoRepo,
      nodeDataSource: fakeNodeGateway,
      selectors: [fakeCoinSelector],
      feeEstimator: const P2wpkhFeeEstimator(),
    ),
    send: SendNodeTransactionUseCase(
      nodeDataSource: fakeNodeGateway,
      broadcastDataSource: fakeBroadcast,
    ),
    walletName: 'test_wallet',
  );

  return nodeWorkflow.prepare(
    targetSat: const Satoshi(50000),
    feeRateSatPerVbyte: 10,
  );
}
