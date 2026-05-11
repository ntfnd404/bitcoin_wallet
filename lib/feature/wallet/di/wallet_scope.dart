import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Feature-scoped DI entry point for the wallet feature.
///
/// Creates a session-level [WalletBloc] via [BlocProvider] so all routes
/// below share the same instance. Lifecycle is managed by [BlocProvider].
class WalletScope extends StatelessWidget {
  const WalletScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);

    return BlocProvider<WalletBloc>(
      create: (_) => WalletBloc(
        walletRepository: deps.wallet.walletRepository,
        getSeed: deps.keys.getSeed,
        createNodeWallet: deps.wallet.createNodeWallet,
        createHdWallet: deps.wallet.createHdWallet,
        restoreHdWallet: deps.wallet.restoreHdWallet,
      ),
      child: child,
    );
  }
}
