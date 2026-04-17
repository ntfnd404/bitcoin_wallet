import 'package:shared_kernel/shared_kernel.dart';
import 'package:test/test.dart';
import 'package:transaction/transaction.dart';

void main() {
  final now = DateTime(2026, 4, 18, 12);

  group('Transaction', () {
    test('isMempool is true when confirmations == 0', () {
      final tx = Transaction(
        txid: 'abc',
        direction: TransactionDirection.incoming,
        amountSat: 100000,
        confirmations: 0,
        timestamp: now,
      );

      expect(tx.isMempool, isTrue);
      expect(tx.isConfirmed, isFalse);
      expect(tx.isConflicted, isFalse);
    });

    test('isConfirmed is true when confirmations > 0', () {
      final tx = Transaction(
        txid: 'abc',
        direction: TransactionDirection.outgoing,
        amountSat: -50000,
        confirmations: 3,
        timestamp: now,
      );

      expect(tx.isConfirmed, isTrue);
      expect(tx.isMempool, isFalse);
      expect(tx.isConflicted, isFalse);
    });

    test('isConflicted is true when confirmations < 0', () {
      final tx = Transaction(
        txid: 'abc',
        direction: TransactionDirection.outgoing,
        amountSat: -50000,
        confirmations: -1,
        timestamp: now,
      );

      expect(tx.isConflicted, isTrue);
      expect(tx.isMempool, isFalse);
      expect(tx.isConfirmed, isFalse);
    });

    test('feeSat is null when not provided', () {
      final tx = Transaction(
        txid: 'abc',
        direction: TransactionDirection.incoming,
        amountSat: 100000,
        confirmations: 1,
        timestamp: now,
      );

      expect(tx.feeSat, isNull);
    });

    test('feeSat is set when provided', () {
      final tx = Transaction(
        txid: 'abc',
        direction: TransactionDirection.outgoing,
        amountSat: -100000,
        feeSat: -1000,
        confirmations: 1,
        timestamp: now,
      );

      expect(tx.feeSat, equals(-1000));
    });
  });

  group('Utxo', () {
    test('isMempool is true when confirmations == 0', () {
      final utxo = Utxo(
        txid: 'def',
        vout: 0,
        amountSat: 500000,
        confirmations: 0,
        address: 'bcrt1q...',
        scriptPubKey: '0014...',
        type: AddressType.nativeSegwit,
        spendable: true,
      );

      expect(utxo.isMempool, isTrue);
    });

    test('isMempool is false when confirmed', () {
      final utxo = Utxo(
        txid: 'def',
        vout: 1,
        amountSat: 200000,
        confirmations: 6,
        address: 'bcrt1p...',
        scriptPubKey: '5120...',
        type: AddressType.taproot,
        spendable: true,
      );

      expect(utxo.isMempool, isFalse);
    });

    test('holds all fields correctly', () {
      final utxo = Utxo(
        txid: 'abc123',
        vout: 2,
        amountSat: 1000000,
        confirmations: 1,
        address: 'bcrt1qtest',
        scriptPubKey: '0014abcdef',
        type: AddressType.nativeSegwit,
        spendable: false,
      );

      expect(utxo.txid, equals('abc123'));
      expect(utxo.vout, equals(2));
      expect(utxo.amountSat, equals(1000000));
      expect(utxo.confirmations, equals(1));
      expect(utxo.address, equals('bcrt1qtest'));
      expect(utxo.scriptPubKey, equals('0014abcdef'));
      expect(utxo.type, equals(AddressType.nativeSegwit));
      expect(utxo.spendable, isFalse);
    });
  });
}
