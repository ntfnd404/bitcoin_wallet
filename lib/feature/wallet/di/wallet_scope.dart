import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet/wallet_bloc.dart';
import 'package:bitcoin_wallet/feature/wallet/domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Feature-scoped DI entry point for the wallet feature.
///
/// Composition root: creates all use cases from [AppDependencies]
/// and wires them to a session-level [WalletBloc] via [BlocProvider].
///
/// All screens in the wallet feature share the same [WalletBloc] instance,
/// ensuring consistent state across navigation.
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
  // Use cases — wallet
  late final GetWalletsUseCase _getWallets;
  late final CreateNodeWalletUseCase _createNodeWallet;
  late final CreateHdWalletUseCase _createHdWallet;
  late final RestoreHdWalletUseCase _restoreHdWallet;
  late final GetSeedUseCase _getSeed;

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);

    // Create wallet use cases
    _getWallets = GetWalletsUseCase(walletRepository: dependencies.walletRepository);

    _createNodeWallet = CreateNodeWalletUseCase(
      gateway: dependencies.bitcoinCoreGateway,
      walletRepository: dependencies.walletRepository,
    );

    _createHdWallet = CreateHdWalletUseCase(
      bip39Service: dependencies.bip39Service,
      seedRepository: dependencies.seedRepository,
      walletRepository: dependencies.walletRepository,
    );

    _restoreHdWallet = RestoreHdWalletUseCase(
      bip39Service: dependencies.bip39Service,
      seedRepository: dependencies.seedRepository,
      walletRepository: dependencies.walletRepository,
    );

    _getSeed = GetSeedUseCase(seedRepository: dependencies.seedRepository);
  }

  @override
  Widget build(BuildContext context) => BlocProvider<WalletBloc>(
    create: (_) => WalletBloc(
      getWallets: _getWallets,
      createNodeWallet: _createNodeWallet,
      createHdWallet: _createHdWallet,
      restoreHdWallet: _restoreHdWallet,
      getSeed: _getSeed,
    ),
    child: widget.child,
  );
}
