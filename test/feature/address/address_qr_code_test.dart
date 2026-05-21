import 'package:bitcoin_wallet/feature/address/view/screen/address_screen.dart';
import 'package:bitcoin_wallet/feature/address/view/widget/address_qr_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/wallet.dart';

Address _address(String value) => Address(
  value: value,
  type: AddressType.nativeSegwit,
  walletId: 'w1',
  index: 0,
);

void main() {
  group('AddressQrCode', () {
    // AQR1: [QR] placeholder replaced
    testWidgets('AQR1: AddressScreen does not show [QR] placeholder text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AddressScreen(address: _address('bcrt1qtest'))),
      );

      expect(find.text('[QR]'), findsNothing);
    });

    // AQR2: all four address types render without crash
    for (final (label, addr) in [
      ('legacy P2PKH', 'mzBc4XEFSdzCDcTxAgf6EZXgsZWpztRhef'),
      ('wrapped SegWit', '2MzQwSSnBHWHqSAqtTVQ6v47XtaisrJa1Vc'),
      ('native SegWit', 'bcrt1qw508d6qejxtdg4y5r3zarvary0c5xw7kygt080'),
      ('Taproot', 'bcrt1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqzk5jj'),
    ]) {
      testWidgets('AQR2: $label address renders QrImageView without crash', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: AddressQrCode(address: addr))),
        );

        expect(find.byType(QrImageView), findsOneWidget);
      });
    }

    // AQR3: semantics label
    testWidgets('AQR3: AddressQrCode has correct semantics label', (tester) async {
      const addr = 'bcrt1qtest';
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AddressQrCode(address: addr))),
      );

      expect(
        find.bySemanticsLabel('QR code for address $addr'),
        findsOneWidget,
      );
    });
  });
}
