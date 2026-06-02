import 'package:rpc_client/rpc_client.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/src/application/signer/node_rpc_signer.dart';
import 'package:transaction/transaction.dart';

import '../fakes/fake_broadcast_gateway.dart';
import '../fakes/fake_node_transaction_gateway.dart';

void main() {
  group('NodeRpcSigner', () {
    late FakeNodeTransactionGateway nodeGateway;
    late FakeBroadcastGateway broadcastGateway;
    late NodeRpcSigner signer;

    setUp(() {
      nodeGateway = FakeNodeTransactionGateway();
      broadcastGateway = FakeBroadcastGateway();
      signer = NodeRpcSigner(
        walletName: 'node_wallet_1',
        nodeTransactionGateway: nodeGateway,
        broadcastGateway: broadcastGateway,
      );
    });

    test('happy path — returns broadcast txid for NodeSignerPayload', () async {
      final txid = await signer.signAndBroadcast(
        strategy: _buildStrategy(),
        signingContext: const NodeSignerPayload(),
        recipientAddress: 'bcrt1qrecipient',
        amountSat: const Satoshi(99000),
        changeAddress: 'bcrt1qchange',
      );

      expect(txid, 'txid_abc123');
      expect(nodeGateway.capturedSignWalletName, 'node_wallet_1');
    });

    test('rejection — HdSignerPayload throws TransactionSigningException with no RPC side effect', () async {
      await expectLater(
        signer.signAndBroadcast(
          strategy: _buildStrategy(),
          signingContext: HdSignerPayload(const {}),
          recipientAddress: 'bcrt1qrecipient',
          amountSat: const Satoshi(99000),
          changeAddress: 'bcrt1qchange',
        ),
        throwsA(isA<TransactionSigningException>()),
      );
      expect(nodeGateway.capturedSignWalletName, isNull);
    });

    test('typed propagation — TransactionBroadcastException is rethrown unchanged', () async {
      broadcastGateway.broadcastThrows = const TransactionBroadcastException();

      await expectLater(
        signer.signAndBroadcast(
          strategy: _buildStrategy(),
          signingContext: const NodeSignerPayload(),
          recipientAddress: 'bcrt1qrecipient',
          amountSat: const Satoshi(99000),
          changeAddress: 'bcrt1qchange',
        ),
        throwsA(isA<TransactionBroadcastException>()),
      );
    });

    test('RpcException from RPC sign call translates to TransactionBroadcastException', () async {
      nodeGateway.signRawTxThrows = const RpcException(
        'signrawtransactionwithwallet',
        {'code': -5, 'message': 'No private key'},
      );

      await expectLater(
        signer.signAndBroadcast(
          strategy: _buildStrategy(),
          signingContext: const NodeSignerPayload(),
          recipientAddress: 'bcrt1qrecipient',
          amountSat: const Satoshi(99000),
          changeAddress: 'bcrt1qchange',
        ),
        throwsA(isA<TransactionBroadcastException>()),
      );
    });

    test('programmer errors propagate — TypeError from gateway is not wrapped', () async {
      nodeGateway.signRawTxThrows = TypeError();

      await expectLater(
        signer.signAndBroadcast(
          strategy: _buildStrategy(),
          signingContext: const NodeSignerPayload(),
          recipientAddress: 'bcrt1qrecipient',
          amountSat: const Satoshi(99000),
          changeAddress: 'bcrt1qchange',
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });
}

CoinSelectionStrategyResult _buildStrategy() {
  const candidate = CoinCandidate(
    txid: 'utxo_txid',
    vout: 0,
    amountSat: Satoshi(100000),
    age: 1,
  );

  return const CoinSelectionStrategyResult(
    name: 'fifo',
    isStochastic: false,
    result: CoinSelectionResult(
      inputs: [candidate],
      totalInputSat: Satoshi(100000),
      feeSat: Satoshi(1000),
      changeSat: Satoshi.zero,
    ),
  );
}
