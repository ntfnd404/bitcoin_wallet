import 'package:bitcoin_wallet/feature/address/di/address_scope.dart';
import 'package:bitcoin_wallet/feature/send/di/send_scope.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/di/manual_utxo_scope.dart';
import 'package:bitcoin_wallet/feature/signing/xpub/di/xpub_scope.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/di/transaction_detail_scope.dart';
import 'package:bitcoin_wallet/feature/transaction/list/di/transaction_list_scope.dart';
import 'package:bitcoin_wallet/feature/utxo/di/utxo_scope.dart';
import 'package:bitcoin_wallet/feature/wallet/di/wallet_scope.dart';
import 'package:bitcoin_wallet/feature/wallet/view/screen/list/wallet_list_screen.dart';
import 'package:flutter/material.dart';

/// Declarative [RouterDelegate] for the app.
///
/// Provides feature scopes below [MaterialApp] but above [Navigator] so all
/// pushed routes share session-level DI without coupling [App] to any
/// specific BLoC. Each scope is responsible for a single sub-feature.
final class AppRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => WalletScope(
    child: AddressScope(
      child: TransactionListScope(
        child: TransactionDetailScope(
          child: UtxoScope(
            child: XpubScope(
              child: ManualUtxoScope(
                child: SendScope(
                  child: Navigator(
                    key: navigatorKey,
                    onGenerateInitialRoutes: (navigator, initialRoute) => [
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(name: '/'),
                        builder: (_) => const WalletListScreen(),
                      ),
                    ],
                    onUnknownRoute: (_) => MaterialPageRoute<void>(
                      builder: (_) => const WalletListScreen(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Future<void> setNewRoutePath(Object configuration) async {}
}
