import 'package:test/test.dart';
import 'package:transaction/src/application/send_workflow.dart';
import 'package:transaction/transaction_assembly.dart';
import 'package:wallet/wallet.dart';

import '../fakes/fake_address_repository.dart';
import '../fakes/fake_block_generation_gateway.dart';
import '../fakes/fake_broadcast_gateway.dart';
import '../fakes/fake_fee_estimator.dart';
import '../fakes/fake_node_transaction_gateway.dart';
import '../fakes/fake_transaction_history_gateway.dart';
import '../fakes/fake_transaction_signer.dart';
import '../fakes/fake_utxo_gateway.dart';
import '../fakes/fake_utxo_scan_gateway.dart';

void main() {
  late TransactionAssembly assembly;

  final nodeWallet = NodeWallet(id: 'n1', name: 'test_wallet', createdAt: DateTime(2025));
  final hdWallet = HdWallet(id: 'h1', name: 'hd_wallet', createdAt: DateTime(2025));

  setUp(() {
    assembly = TransactionAssembly(
      transactionRemoteDataSource: FakeTransactionHistoryGateway(),
      utxoRemoteDataSource: FakeUtxoGateway(),
      utxoScanDataSource: FakeUtxoScanGateway(),
      broadcastDataSource: FakeBroadcastGateway(),
      nodeTransactionDataSource: FakeNodeTransactionGateway(),
      blockGenerationDataSource: FakeBlockGenerationGateway(),
      addressRepository: FakeAddressRepository(),
      coinSelectors: const [],
      feeEstimator: FakeFeeEstimator(),
      hdSigner: FakeTransactionSigner(),
      bech32Hrp: 'bcrt',
    );
  });

  group('TransactionAssembly factory methods', () {
    // AF1
    test('buildAutoSendWorkflow(NodeWallet) returns non-null SendWorkflow', () {
      final workflow = assembly.buildAutoSendWorkflow(nodeWallet);
      expect(workflow, isA<SendWorkflow>());
    });

    // AF2
    test('buildAutoSendWorkflow(HdWallet) returns non-null SendWorkflow', () {
      final workflow = assembly.buildAutoSendWorkflow(hdWallet);
      expect(workflow, isA<SendWorkflow>());
    });

    // AF3
    test('buildPinnedSendWorkflow(NodeWallet, []) returns non-null SendWorkflow', () {
      final workflow = assembly.buildPinnedSendWorkflow(nodeWallet, const []);
      expect(workflow, isA<SendWorkflow>());
    });

    // AF4
    test('buildPinnedSendWorkflow(HdWallet, []) returns non-null SendWorkflow', () {
      final workflow = assembly.buildPinnedSendWorkflow(hdWallet, const []);
      expect(workflow, isA<SendWorkflow>());
    });
  });
}
