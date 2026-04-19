import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_bloc.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_bloc.dart';
import 'package:flutter/widgets.dart';

/// Feature-scoped DI entry point for the transaction feature.
///
/// Exposes factory methods for [TransactionBloc] (list flow) and
/// [TransactionDetailBloc] (detail flow).
/// Use cases come from [TransactionAssembly] via [AppScope].
class TransactionScope extends StatefulWidget {
  const TransactionScope({super.key, required this.child});

  /// Creates a new [TransactionBloc] wired with use cases from the nearest
  /// [TransactionScope] ancestor.
  static TransactionBloc newTransactionBloc(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<_InheritedTransactionScope>();
    if (scope == null) {
      throw StateError('TransactionScope not found in widget tree');
    }

    return scope.newTransactionBloc();
  }

  /// Creates a new [TransactionDetailBloc] wired with use cases from the nearest
  /// [TransactionScope] ancestor.
  static TransactionDetailBloc newTransactionDetailBloc(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<_InheritedTransactionScope>();
    if (scope == null) {
      throw StateError('TransactionScope not found in widget tree');
    }

    return scope.newTransactionDetailBloc();
  }

  final Widget child;

  @override
  State<TransactionScope> createState() => _TransactionScopeState();
}

class _TransactionScopeState extends State<TransactionScope> {
  late final TransactionBloc Function() _blocFactory;
  late final TransactionDetailBloc Function() _detailBlocFactory;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);
    final tx = deps.transaction;

    _blocFactory = () => TransactionBloc(getTransactions: tx.getTransactions);
    _detailBlocFactory =
        () => TransactionDetailBloc(getDetail: tx.getTransactionDetail);
  }

  @override
  Widget build(BuildContext context) => _InheritedTransactionScope(
        newTransactionBloc: _blocFactory,
        newTransactionDetailBloc: _detailBlocFactory,
        child: widget.child,
      );
}

class _InheritedTransactionScope extends InheritedWidget {
  const _InheritedTransactionScope({
    required this.newTransactionBloc,
    required this.newTransactionDetailBloc,
    required super.child,
  });

  final TransactionBloc Function() newTransactionBloc;
  final TransactionDetailBloc Function() newTransactionDetailBloc;

  @override
  bool updateShouldNotify(_InheritedTransactionScope old) => false;
}
