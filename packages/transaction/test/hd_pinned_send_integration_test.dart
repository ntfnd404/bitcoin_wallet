/// Integration test: HdPinnedUtxoSource → PrepareSendUseCase → HdInAppSigner.
///
/// Uses real domain/application implementations and high-fidelity fake
/// infrastructure (AddressRepository, TransactionSigner, BroadcastGateway).
/// Exercises the four invariants specified in BW-0018 Phase 6:
///   HP1 — only pinned inputs reach the signer
///   HP2 — UnknownPinnedInputAddressException on missing address
///   HP3 — dust pinned inputs filtered by PinnedUtxoEligibilityFilter
///   HP4 — MissingSigningInputException when signing context is incomplete
library;

import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/src/application/prepare_send_use_case.dart';
import 'package:transaction/src/application/send_workflow_impl.dart';
import 'package:transaction/src/application/signer/hd_in_app_signer.dart';
import 'package:transaction/src/application/source/hd_pinned_utxo_source.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

import 'fakes/fake_address_repository.dart';
import 'fakes/fake_broadcast_gateway.dart';
import 'fakes/fake_coin_selector.dart';
import 'fakes/fake_fee_estimator.dart';
import 'fakes/fake_transaction_signer.dart';

void main() {
  const walletId = 'hd_wallet_001';
  const bech32Hrp = 'bcrt';

  late FakeAddressRepository addressRepo;
  late FakeTransactionSigner txSigner;
  late FakeBroadcastGateway broadcastGw;
  late FakeCoinSelector selector;
  late FakeFeeEstimator feeEstimator;

  setUp(() {
    addressRepo = FakeAddressRepository();
    txSigner = FakeTransactionSigner();
    broadcastGw = FakeBroadcastGateway();
    selector = FakeCoinSelector(name: 'fifo');
    feeEstimator = FakeFeeEstimator();
  });

  SendWorkflowImpl _buildWorkflow(List<Utxo> pinned) {
    final source = HdPinnedUtxoSource(
      walletId: walletId,
      pinnedInputs: pinned,
      addressRepository: addressRepo,
    );
    final signer = HdInAppSigner(
      walletId: walletId,
      bech32Hrp: bech32Hrp,
      transactionSigner: txSigner,
      broadcastGateway: broadcastGw,
    );
    final prepare = PrepareSendUseCase(
      selectors: [selector],
      feeEstimator: feeEstimator,
      eligibilityFilter: const PinnedUtxoEligibilityFilter(),
    );

    return SendWorkflowImpl(source: source, signer: signer, prepare: prepare);
  }

  // HP1 — only pinned inputs reach the signer
  test('HP1: signed tx contains exactly the pinned inputs', () async {
    addressRepo.addresses = [
      _address('bcrt1qaddr0', index: 0),
      _address('bcrt1qaddr1', index: 1),
    ];
    final pinned = [
      _utxo(txid: 'tx_a', vout: 0, address: 'bcrt1qaddr0', sat: 50000),
      _utxo(txid: 'tx_b', vout: 1, address: 'bcrt1qaddr1', sat: 80000),
    ];

    final workflow = _buildWorkflow(pinned);
    final prep = await workflow.prepare(targetSat: const Satoshi(40000), feeRateSatPerVbyte: 10);
    await workflow.confirm(
      preparation: prep,
      strategyName: 'fifo',
      recipientAddress: 'bcrt1qrecipient',
      amountSat: const Satoshi(40000),
    );

    final inputs = txSigner.capturedInputs!;
    expect(inputs, hasLength(2));
    expect(inputs.map((i) => i.txid), containsAll(<String>['tx_a', 'tx_b']));
    expect(inputs.firstWhere((i) => i.txid == 'tx_a').derivationIndex, 0);
    expect(inputs.firstWhere((i) => i.txid == 'tx_b').derivationIndex, 1);
  });

  // HP2 — UnknownPinnedInputAddressException on missing address
  test('HP2: prepare throws UnknownPinnedInputAddressException when address absent', () async {
    addressRepo.addresses = [_address('bcrt1qknown', index: 0)];
    final pinned = [_utxo(txid: 'tx_miss', vout: 0, address: 'bcrt1qmissing', sat: 50000)];

    final workflow = _buildWorkflow(pinned);

    await expectLater(
      () => workflow.prepare(targetSat: const Satoshi(40000), feeRateSatPerVbyte: 10),
      throwsA(
        isA<UnknownPinnedInputAddressException>()
            .having((e) => e.txid, 'txid', 'tx_miss')
            .having((e) => e.vout, 'vout', 0)
            .having((e) => e.address, 'address', 'bcrt1qmissing'),
      ),
    );
  });

  // HP3 — dust pinned inputs filtered by PinnedUtxoEligibilityFilter
  // FakeFeeEstimator.inputVbytes = 68. At feeRate=10: cost = 680 sat.
  // dust UTXO (500 sat): effectiveSatoshis = 500 - 680 = -180 <= 0 → filtered out.
  // valid UTXO (50000 sat): effectiveSatoshis = 49320 > 0 → kept.
  test('HP3: dust pinned inputs are filtered; only non-dust inputs reach the signer', () async {
    addressRepo.addresses = [
      _address('bcrt1qdust', index: 0),
      _address('bcrt1qvalid', index: 1),
    ];
    final pinned = [
      _utxo(txid: 'tx_dust', vout: 0, address: 'bcrt1qdust', sat: 500),
      _utxo(txid: 'tx_valid', vout: 0, address: 'bcrt1qvalid', sat: 50000),
    ];

    final workflow = _buildWorkflow(pinned);
    final prep = await workflow.prepare(targetSat: const Satoshi(30000), feeRateSatPerVbyte: 10);
    await workflow.confirm(
      preparation: prep,
      strategyName: 'fifo',
      recipientAddress: 'bcrt1qrecipient',
      amountSat: const Satoshi(30000),
    );

    final inputs = txSigner.capturedInputs!;
    expect(inputs, hasLength(1));
    expect(inputs.single.txid, 'tx_valid');
  });

  // HP4 — MissingSigningInputException when signing context incomplete
  // Tested directly against HdInAppSigner: strategy selects a candidate
  // whose (txid, vout) key is absent from HdSignerPayload.inputs.
  test('HP4: HdInAppSigner throws MissingSigningInputException on missing signing input', () async {
    const candidate = CoinCandidate(
      txid: 'tx_orphan',
      vout: 0,
      amountSat: Satoshi(100000),
      age: 1,
    );
    // Payload contains tx_other but NOT tx_orphan.
    final incompletePayload = HdSignerPayload(const {
      ('tx_other', 0): SigningInput(
        txid: 'tx_other',
        vout: 0,
        amountSat: Satoshi(50000),
        address: 'bcrt1qother',
        derivationIndex: 0,
        addressType: AddressType.nativeSegwit,
      ),
    });

    final signer = HdInAppSigner(
      walletId: walletId,
      bech32Hrp: bech32Hrp,
      transactionSigner: txSigner,
      broadcastGateway: broadcastGw,
    );

    final strategy = CoinSelectionStrategyResult(
      name: 'fifo',
      isStochastic: false,
      result: CoinSelectionResult(
        inputs: const [candidate],
        totalInputSat: const Satoshi(100000),
        feeSat: const Satoshi(1000),
        changeSat: const Satoshi(49000),
      ),
    );

    await expectLater(
      () => signer.signAndBroadcast(
        strategy: strategy,
        signingContext: incompletePayload,
        recipientAddress: 'bcrt1qrecipient',
        amountSat: const Satoshi(50000),
        changeAddress: 'bcrt1qchange',
      ),
      throwsA(
        isA<MissingSigningInputException>()
            .having((e) => e.txid, 'txid', 'tx_orphan')
            .having((e) => e.vout, 'vout', 0),
      ),
    );
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Address _address(String value, {required int index}) => Address(
  value: value,
  type: AddressType.nativeSegwit,
  walletId: 'hd_wallet_001',
  index: index,
);

Utxo _utxo({
  required String txid,
  required int vout,
  required String address,
  required int sat,
}) => Utxo(
  txid: txid,
  vout: vout,
  amountSat: Satoshi(sat),
  confirmations: 6,
  address: address,
  scriptPubKey: '0014abcdef',
  type: AddressType.nativeSegwit,
  spendable: true,
);
