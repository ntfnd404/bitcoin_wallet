import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/signing/xpub/bloc/xpub_bloc.dart';
import 'package:flutter/widgets.dart';

class XpubScope extends StatefulWidget {
  const XpubScope({super.key, required this.child});

  static XpubBloc newXpubBloc(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_InheritedXpubScope>();
    if (scope == null) throw StateError('XpubScope not found in widget tree');

    return scope.newXpubBloc();
  }

  final Widget child;

  @override
  State<XpubScope> createState() => _XpubScopeState();
}

class _XpubScopeState extends State<XpubScope> {
  late final XpubBloc Function() _factory;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);
    _factory = () => XpubBloc(getXpub: deps.keys.getXpub);
  }

  @override
  Widget build(BuildContext context) => _InheritedXpubScope(
    newXpubBloc: _factory,
    child: widget.child,
  );
}

class _InheritedXpubScope extends InheritedWidget {
  const _InheritedXpubScope({
    required this.newXpubBloc,
    required super.child,
  });

  final XpubBloc Function() newXpubBloc;

  @override
  bool updateShouldNotify(_InheritedXpubScope old) => false;
}
