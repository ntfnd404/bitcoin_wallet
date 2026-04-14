import 'package:bitcoin_wallet/core/di/app_dependencies.dart';
import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/core/routing/app_router.dart';
import 'package:bitcoin_wallet/feature/address/di/address_scope.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_bloc.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_event.dart';
import 'package:bitcoin_wallet/feature/wallet/di/wallet_scope.dart';
import 'package:bitcoin_wallet/feature/wallet/view/screen/list/wallet_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Root application widget.
///
/// Composes [AppScope] (app-level DI) and [WalletScope] (feature-level DI).
/// [WalletScope] is the composition root for the wallet feature:
/// it creates all use cases and wires them to BLoCs.
class App extends StatelessWidget {
  const App({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) => AppScope(
    dependencies: dependencies,
    child: WalletScope(
      child: AddressScope(
        child: MaterialApp(
          home: Builder(
            builder: (innerContext) => WalletListScreen(
              onCreateWallet: () async {
                await AppRouter.toCreateWallet(innerContext);
                if (innerContext.mounted) {
                  innerContext.read<WalletBloc>().add(const WalletListRequested());
                }
              },
              onWalletSelected: (wallet) => AppRouter.toWalletDetail(innerContext, wallet),
            ),
          ),
        ),
      ),
    ),
  );
}
