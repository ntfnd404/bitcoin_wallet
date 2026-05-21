import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:wallet/wallet.dart';

/// Feature-scoped DI entry point for the OP_RETURN transaction flow.
///
/// Reads [SendOpReturnUseCase] from [TransactionAssembly] and exposes a
/// factory for creating [OpReturnBloc] instances per screen.
class OpReturnScope extends StatefulWidget {
  const OpReturnScope({super.key, required this.child});

  /// Returns a new [OpReturnBloc] wired for [wallet] from the nearest scope.
  static OpReturnBloc newBloc(BuildContext context, NodeWallet wallet) {
    final scope = context.getInheritedWidgetOfExactType<_InheritedOpReturnScope>();
    if (scope == null) throw StateError('OpReturnScope not found in widget tree');

    return scope.blocFactory(wallet);
  }

  final Widget child;

  @override
  State<OpReturnScope> createState() => _OpReturnScopeState();
}

class _OpReturnScopeState extends State<OpReturnScope> {
  late final OpReturnBloc Function(NodeWallet) _blocFactory;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);

    _blocFactory = (wallet) => OpReturnBloc(
      useCase: deps.transaction.sendOpReturn,
      eventBus: deps.eventBus,
      walletId: wallet.id,
      walletName: wallet.name,
    );
  }

  @override
  Widget build(BuildContext context) => _InheritedOpReturnScope(
    blocFactory: _blocFactory,
    child: widget.child,
  );
}

class _InheritedOpReturnScope extends InheritedWidget {
  const _InheritedOpReturnScope({
    required this.blocFactory,
    required super.child,
  });

  final OpReturnBloc Function(NodeWallet) blocFactory;

  @override
  bool updateShouldNotify(_InheritedOpReturnScope old) => false;
}
