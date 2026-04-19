import 'package:bitcoin_wallet/feature/address/di/address_scope.dart';
import 'package:bitcoin_wallet/feature/send/di/send_scope.dart';
import 'package:bitcoin_wallet/feature/signing/di/signing_scope.dart';
import 'package:bitcoin_wallet/feature/transaction/di/transaction_scope.dart';
import 'package:bitcoin_wallet/feature/utxo/di/utxo_scope.dart';
import 'package:bitcoin_wallet/feature/wallet/di/wallet_scope.dart';
import 'package:bitcoin_wallet/feature/wallet/view/screen/list/wallet_list_screen.dart';
import 'package:flutter/material.dart';

/// Declarative [RouterDelegate] for the app.
///
/// Provides [WalletScope] and [AddressScope] below [MaterialApp] but above
/// [Navigator] — so all pushed routes share the same session-level [WalletBloc]
/// and have access to the [AddressScope] factory without coupling [App] to
/// any feature-specific BLoC or scope.
///
/// Imperative navigation ([Navigator.push] via [AppRouter]) is preserved —
/// this delegate only manages the initial route and back-button behaviour.
final class AppRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => WalletScope(
    child: AddressScope(
      child: TransactionScope(
        child: UtxoScope(
          child: SigningScope(
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
  );

  @override
  Future<void> setNewRoutePath(Object configuration) async {}
}
