import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_bloc.dart';
import 'package:flutter/widgets.dart';

class ManualUtxoScope extends StatefulWidget {
  const ManualUtxoScope({super.key, required this.child});

  static SigningBloc newSigningBloc(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_InheritedManualUtxoScope>();
    if (scope == null) {
      throw StateError('ManualUtxoScope not found in widget tree');
    }

    return scope.newSigningBloc();
  }

  final Widget child;

  @override
  State<ManualUtxoScope> createState() => _ManualUtxoScopeState();
}

class _ManualUtxoScopeState extends State<ManualUtxoScope> {
  late final SigningBloc Function() _factory;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);
    _factory = () => SigningBloc(
      addressRepository: deps.address.addressRepository,
      scanUtxos: deps.transaction.scanUtxos,
      signTransaction: deps.keys.signTransaction,
      broadcastTransaction: deps.transaction.broadcastTransaction,
    );
  }

  @override
  Widget build(BuildContext context) => _InheritedManualUtxoScope(
    newSigningBloc: _factory,
    child: widget.child,
  );
}

class _InheritedManualUtxoScope extends InheritedWidget {
  const _InheritedManualUtxoScope({
    required this.newSigningBloc,
    required super.child,
  });

  final SigningBloc Function() newSigningBloc;

  @override
  bool updateShouldNotify(_InheritedManualUtxoScope old) => false;
}
