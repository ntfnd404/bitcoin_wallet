import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Feature-scoped DI entry point for the wallet feature.
///
/// Composition root: creates the session-level [WalletBloc] from module
/// assemblies in [didChangeDependencies]. Provides [WalletBloc] to the
/// subtree via [BlocProvider.value] — lifecycle is owned here.
///
/// Placed above [MaterialApp] so all pushed routes share the same instance.
class WalletScope extends StatefulWidget {
  const WalletScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<WalletScope> createState() => _WalletScopeState();
}

class _WalletScopeState extends State<WalletScope> {
  late final WalletBloc _walletBloc;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final deps = AppScope.of(context);
      _walletBloc = WalletBloc(
        walletRepository: deps.wallet.walletRepository,
        seedRepository: deps.keys.seedRepository,
        createNodeWallet: deps.wallet.createNodeWallet,
        createHdWallet: deps.wallet.createHdWallet,
        restoreHdWallet: deps.wallet.restoreHdWallet,
      );
    }
  }

  @override
  void dispose() {
    _walletBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<WalletBloc>.value(
    value: _walletBloc,
    child: widget.child,
  );
}
