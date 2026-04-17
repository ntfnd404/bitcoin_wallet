import 'package:address/address.dart';
import 'package:keys/keys.dart';
import 'package:shared_kernel/shared_kernel.dart';

/// Known BIP39 test vector: 128-bit all-zero entropy.
final kTestMnemonic = Mnemonic(
  words: [
    'abandon',
    'abandon',
    'abandon',
    'abandon',
    'abandon',
    'abandon',
    'abandon',
    'abandon',
    'abandon',
    'abandon',
    'abandon',
    'about',
  ],
);

/// Factory for creating test addresses with customizable fields.
Address testAddress({
  String value = 'bcrt1qtest',
  AddressType type = AddressType.nativeSegwit,
  String walletId = 'w1',
  int index = 0,
}) => Address(value: value, type: type, walletId: walletId, index: index);
