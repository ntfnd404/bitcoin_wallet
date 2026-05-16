import 'package:mocktail/mocktail.dart';
import 'package:wallet/wallet.dart';

class MockWalletRepository extends Mock implements NodeWalletRepository, HdWalletRepository {}
