import 'package:bitcoin_wallet/core/di/app_dependencies.dart';
import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/core/routing/app_router_delegate.dart';
import 'package:flutter/material.dart';

/// Root application widget.
///
/// [AppScope] stays above [MaterialApp] — it has no Navigator dependency.
/// [WalletScope] and [AddressScope] live inside [AppRouterDelegate.build],
/// below [MaterialApp] but above [Navigator].
class App extends StatefulWidget {
  const App({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouterDelegate _delegate;

  @override
  void initState() {
    super.initState();
    _delegate = AppRouterDelegate();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    dependencies: widget.dependencies,
    child: MaterialApp.router(
      routerDelegate: _delegate,
    ),
  );
}
