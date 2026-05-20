import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/wallet.dart';

/// Feature-scoped DI entry point for the regtest mining dev tool.
///
/// Assembles dependencies and exposes a factory for [RegtestMiningBloc].
/// Wallet-type discrimination (NodeWallet vs HdWallet) for address resolution
/// lives here — not inside the BLoC.
class RegtestMiningScope extends StatefulWidget {
  const RegtestMiningScope({super.key, required this.child});

  /// Returns a new [RegtestMiningBloc] wired from the nearest [RegtestMiningScope].
  static RegtestMiningBloc newBloc(BuildContext context, String walletId) {
    final scope = context.getInheritedWidgetOfExactType<_InheritedRegtestMiningScope>();
    if (scope == null) throw StateError('RegtestMiningScope not found in widget tree');

    return scope.blocFactory(walletId);
  }

  final Widget child;

  @override
  State<RegtestMiningScope> createState() => _RegtestMiningScopeState();
}

class _RegtestMiningScopeState extends State<RegtestMiningScope> {
  late final RegtestMiningBloc Function(String walletId) _blocFactory;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);
    final tx = deps.transaction;
    final addressRepository = deps.wallet.addressRepository;

    _blocFactory = (walletId) => RegtestMiningBloc(
      blockGenerationGateway: tx.blockGenerationGateway,
      eventBus: deps.eventBus,
      walletId: walletId,
      addressResolver: (wallet) => switch (wallet) {
        NodeWallet() =>
          tx
              .prepareNodeSend(
                walletName: wallet.name,
                targetSat: const Satoshi(1),
                feeRateSatPerVbyte: 1,
              )
              .then((prep) => prep.changeAddress),
        HdWallet() => addressRepository.getAddresses(wallet.id).then((addrs) {
          final native = addrs.where((a) => a.type == AddressType.nativeSegwit).toList();

          return native.isNotEmpty ? native.first.value : '';
        }),
      },
    );
  }

  @override
  Widget build(BuildContext context) => _InheritedRegtestMiningScope(
    blocFactory: _blocFactory,
    child: widget.child,
  );
}

class _InheritedRegtestMiningScope extends InheritedWidget {
  const _InheritedRegtestMiningScope({
    required this.blocFactory,
    required super.child,
  });

  final RegtestMiningBloc Function(String walletId) blocFactory;

  @override
  bool updateShouldNotify(_InheritedRegtestMiningScope old) => false;
}
