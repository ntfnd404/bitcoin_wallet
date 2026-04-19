import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_bloc.dart';
import 'package:flutter/widgets.dart';

/// Feature-scoped DI entry point for the UTXO feature.
///
/// Composition root: exposes a factory for screen-level [UtxoBloc]
/// instances via [_InheritedUtxoScope].
///
/// Use cases come from [TransactionAssembly]. The router calls [newUtxoBloc]
/// to create a fresh [UtxoBloc] per [UtxoListScreen].
class UtxoScope extends StatefulWidget {
  const UtxoScope({
    super.key,
    required this.child,
  });

  /// Creates a new [UtxoBloc] wired with use cases from the nearest
  /// [UtxoScope] ancestor.
  static UtxoBloc newUtxoBloc(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_InheritedUtxoScope>();
    if (scope == null) throw StateError('UtxoScope not found in widget tree');

    return scope.newUtxoBloc();
  }

  final Widget child;

  @override
  State<UtxoScope> createState() => _UtxoScopeState();
}

class _UtxoScopeState extends State<UtxoScope> {
  late final UtxoBloc Function() _blocFactory;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);
    final transactionAssembly = deps.transaction;

    _blocFactory = () => UtxoBloc(
      getUtxos: transactionAssembly.getUtxos,
    );
  }

  @override
  Widget build(BuildContext context) => _InheritedUtxoScope(
    newUtxoBloc: _blocFactory,
    child: widget.child,
  );
}

class _InheritedUtxoScope extends InheritedWidget {
  const _InheritedUtxoScope({
    required this.newUtxoBloc,
    required super.child,
  });

  final UtxoBloc Function() newUtxoBloc;

  @override
  bool updateShouldNotify(_InheritedUtxoScope old) => false;
}
