import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_bloc.dart';
import 'package:bitcoin_wallet/feature/wallet/domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Feature-scoped DI entry point for the wallet feature.
///
/// Composition root: creates all use cases and the session-level [WalletBloc]
/// in [didChangeDependencies]. Provides [WalletBloc] to the subtree via
/// [BlocProvider.value] — lifecycle is owned here (created + disposed).
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
        walletRepository: deps.walletRepository,
        seedRepository: deps.seedRepository,
        createNodeWallet: CreateNodeWalletUseCase(
          remoteDataSource: deps.bitcoinCoreRemoteDataSource,
          walletRepository: deps.walletRepository,
        ),
        createHdWallet: CreateHdWalletUseCase(
          bip39Service: deps.bip39Service,
          seedRepository: deps.seedRepository,
          walletRepository: deps.walletRepository,
        ),
        restoreHdWallet: RestoreHdWalletUseCase(
          bip39Service: deps.bip39Service,
          seedRepository: deps.seedRepository,
          walletRepository: deps.walletRepository,
        ),
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
