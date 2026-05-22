import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/utxo/bloc/utxo_picker/utxo_picker_bloc.dart';
import 'package:flutter/widgets.dart';

/// Feature-scoped DI for the UTXO picker flow.
///
/// Reads [UtxoRepository] and [FeeEstimator] from [AppScope] and exposes
/// a factory for [UtxoPickerBloc]. Deliberately independent of [SendScope].
class UtxoPickerScope extends StatefulWidget {
  const UtxoPickerScope({super.key, required this.child});

  static UtxoPickerBloc newBloc(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_InheritedUtxoPickerScope>();
    if (scope == null) {
      throw StateError('UtxoPickerScope not found in widget tree');
    }

    return scope.blocFactory();
  }

  final Widget child;

  @override
  State<UtxoPickerScope> createState() => _UtxoPickerScopeState();
}

class _UtxoPickerScopeState extends State<UtxoPickerScope> {
  late final UtxoPickerBloc Function() _blocFactory;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);

    _blocFactory = () => UtxoPickerBloc(
      utxoRepository: deps.transaction.utxoRepository,
      feeEstimator: deps.transaction.feeEstimator,
    );
  }

  @override
  Widget build(BuildContext context) => _InheritedUtxoPickerScope(
    blocFactory: _blocFactory,
    child: widget.child,
  );
}

class _InheritedUtxoPickerScope extends InheritedWidget {
  const _InheritedUtxoPickerScope({
    required this.blocFactory,
    required super.child,
  });

  final UtxoPickerBloc Function() blocFactory;

  @override
  bool updateShouldNotify(_InheritedUtxoPickerScope old) => false;
}
