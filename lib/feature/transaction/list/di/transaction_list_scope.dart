import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/transaction/list/bloc/transaction_bloc.dart';
import 'package:flutter/widgets.dart';

class TransactionListScope extends StatefulWidget {
  const TransactionListScope({super.key, required this.child});

  static TransactionBloc newTransactionBloc(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<_InheritedTransactionListScope>();
    if (scope == null) {
      throw StateError('TransactionListScope not found in widget tree');
    }

    return scope.newTransactionBloc();
  }

  final Widget child;

  @override
  State<TransactionListScope> createState() => _TransactionListScopeState();
}

class _TransactionListScopeState extends State<TransactionListScope> {
  late final TransactionBloc Function() _factory;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);
    _factory = () => TransactionBloc(getTransactions: deps.transaction.getTransactions);
  }

  @override
  Widget build(BuildContext context) => _InheritedTransactionListScope(
        newTransactionBloc: _factory,
        child: widget.child,
      );
}

class _InheritedTransactionListScope extends InheritedWidget {
  const _InheritedTransactionListScope({
    required this.newTransactionBloc,
    required super.child,
  });

  final TransactionBloc Function() newTransactionBloc;

  @override
  bool updateShouldNotify(_InheritedTransactionListScope old) => false;
}
