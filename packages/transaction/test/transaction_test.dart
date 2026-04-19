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
        amountSat: const Satoshi(100000),
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
        amountSat: const Satoshi(-50000),
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
        amountSat: const Satoshi(-50000),
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
        amountSat: const Satoshi(100000),
        confirmations: 1,
        timestamp: now,
      );

      expect(tx.feeSat, isNull);
    });

    test('feeSat is set when provided', () {
      final tx = Transaction(
        txid: 'abc',
        direction: TransactionDirection.outgoing,
        amountSat: const Satoshi(-100000),
        feeSat: const Satoshi(-1000),
        confirmations: 1,
        timestamp: now,
      );

      expect(tx.feeSat, equals(const Satoshi(-1000)));
    });
  });

  group('Utxo', () {
    test('isMempool is true when confirmations == 0', () {
      const utxo = Utxo(
        txid: 'def',
        vout: 0,
        amountSat: Satoshi(500000),
        confirmations: 0,
        address: 'bcrt1q...',
        scriptPubKey: '0014...',
        type: AddressType.nativeSegwit,
        spendable: true,
      );

      expect(utxo.isMempool, isTrue);
    });

    test('isMempool is false when confirmed', () {
      const utxo = Utxo(
        txid: 'def',
        vout: 1,
        amountSat: Satoshi(200000),
        confirmations: 6,
        address: 'bcrt1p...',
        scriptPubKey: '5120...',
        type: AddressType.taproot,
        spendable: true,
      );

      expect(utxo.isMempool, isFalse);
    });

    test('holds all fields correctly', () {
      const utxo = Utxo(
        txid: 'abc123',
        vout: 2,
        amountSat: Satoshi(1000000),
        confirmations: 1,
        address: 'bcrt1qtest',
        scriptPubKey: '0014abcdef',
        type: AddressType.nativeSegwit,
        spendable: false,
      );

      expect(utxo.txid, equals('abc123'));
      expect(utxo.vout, equals(2));
      expect(utxo.amountSat, equals(const Satoshi(1000000)));
      expect(utxo.confirmations, equals(1));
      expect(utxo.address, equals('bcrt1qtest'));
      expect(utxo.scriptPubKey, equals('0014abcdef'));
      expect(utxo.type, equals(AddressType.nativeSegwit));
      expect(utxo.spendable, isFalse);
    });

    test('address can be null for OP_RETURN and other non-addressable outputs', () {
      const utxo = Utxo(
        txid: 'def456',
        vout: 0,
        amountSat: Satoshi(0),
        confirmations: 1,
        address: null,
        scriptPubKey: '6a04746573740a',
        type: AddressType.legacy,
        spendable: false,
      );

      expect(utxo.address, isNull);
    });

    test('two UTXOs with same txid and vout are equal', () {
      const utxo1 = Utxo(
        txid: 'abc123',
        vout: 0,
        amountSat: Satoshi(100000),
        confirmations: 1,
        address: 'bcrt1q...',
        scriptPubKey: '0014...',
        type: AddressType.nativeSegwit,
        spendable: true,
      );

      const utxo2 = Utxo(
        txid: 'abc123',
        vout: 0,
        amountSat: Satoshi(200000), // different amount
        confirmations: 2, // different confirmations
        address: 'bcrt1qother',
        scriptPubKey: '0014other',
        type: AddressType.legacy,
        spendable: false,
      );

      expect(utxo1, equals(utxo2));
      expect(utxo1.hashCode, equals(utxo2.hashCode));
    });

    test('two UTXOs with different vout are not equal', () {
      const utxo1 = Utxo(
        txid: 'abc123',
        vout: 0,
        amountSat: Satoshi(100000),
        confirmations: 1,
        address: 'bcrt1q...',
        scriptPubKey: '0014...',
        type: AddressType.nativeSegwit,
        spendable: true,
      );

      const utxo2 = Utxo(
        txid: 'abc123',
        vout: 1,
        amountSat: Satoshi(100000),
        confirmations: 1,
        address: 'bcrt1q...',
        scriptPubKey: '0014...',
        type: AddressType.nativeSegwit,
        spendable: true,
      );

      expect(utxo1, isNot(equals(utxo2)));
    });
  });

  group('Transaction', () {
    test('two transactions with same txid are equal', () {
      final tx1 = Transaction(
        txid: 'abc123',
        direction: TransactionDirection.incoming,
        amountSat: const Satoshi(100000),
        confirmations: 1,
        timestamp: now,
      );

      final tx2 = Transaction(
        txid: 'abc123',
        direction: TransactionDirection.outgoing,
        amountSat: const Satoshi(500000),
        confirmations: 5,
        timestamp: now,
      );

      expect(tx1, equals(tx2));
      expect(tx1.hashCode, equals(tx2.hashCode));
    });

    test('two transactions with different txid are not equal', () {
      final tx1 = Transaction(
        txid: 'abc123',
        direction: TransactionDirection.incoming,
        amountSat: const Satoshi(100000),
        confirmations: 1,
        timestamp: now,
      );

      final tx2 = Transaction(
        txid: 'def456',
        direction: TransactionDirection.incoming,
        amountSat: const Satoshi(100000),
        confirmations: 1,
        timestamp: now,
      );

      expect(tx1, isNot(equals(tx2)));
    });
  });
}
