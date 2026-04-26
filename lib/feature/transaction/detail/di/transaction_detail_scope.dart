import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/bloc/transaction_detail_bloc.dart';
import 'package:flutter/widgets.dart';

class TransactionDetailScope extends StatefulWidget {
  const TransactionDetailScope({super.key, required this.child});

  static TransactionDetailBloc newTransactionDetailBloc(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_InheritedTransactionDetailScope>();
    if (scope == null) {
      throw StateError('TransactionDetailScope not found in widget tree');
    }

    return scope.newTransactionDetailBloc();
  }

  final Widget child;

  @override
  State<TransactionDetailScope> createState() => _TransactionDetailScopeState();
}

class _TransactionDetailScopeState extends State<TransactionDetailScope> {
  late final TransactionDetailBloc Function() _factory;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);
    _factory = () => TransactionDetailBloc(getDetail: deps.transaction.getTransactionDetail);
  }

  @override
  Widget build(BuildContext context) => _InheritedTransactionDetailScope(
    newTransactionDetailBloc: _factory,
    child: widget.child,
  );
}

class _InheritedTransactionDetailScope extends InheritedWidget {
  const _InheritedTransactionDetailScope({
    required this.newTransactionDetailBloc,
    required super.child,
  });

  final TransactionDetailBloc Function() newTransactionDetailBloc;

  @override
  bool updateShouldNotify(_InheritedTransactionDetailScope old) => false;
}
