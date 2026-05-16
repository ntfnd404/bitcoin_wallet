import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// Feature-scoped DI entry point for the send flow.
///
/// Reads use cases from [AppDependencies.transaction] and creates the correct
/// [SendWorkflow] implementation based on wallet type. Wallet identity is
/// captured in the workflow at construction time.
class SendScope extends StatefulWidget {
  const SendScope({super.key, required this.child});

  /// Creates a new [SendBloc] for [wallet] from the nearest [SendScope] ancestor.
  static SendBloc newSendBloc(BuildContext context, Wallet wallet) {
    final scope = context.getInheritedWidgetOfExactType<_InheritedSendScope>();
    if (scope == null) throw StateError('SendScope not found in widget tree');

    return scope.blocFactory(wallet);
  }

  final Widget child;

  @override
  State<SendScope> createState() => _SendScopeState();
}

class _SendScopeState extends State<SendScope> {
  late final SendBloc Function(Wallet) _blocFactory;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);
    final tx = deps.transaction;
    final bech32Hrp = deps.network.bech32Hrp;
    final eventBus = deps.eventBus;

    _blocFactory = (wallet) => SendBloc(
      workflow: switch (wallet) {
        NodeWallet() => NodeSendWorkflow(
          prepare: tx.prepareNodeSend,
          send: tx.sendNodeTransaction,
          walletName: wallet.name,
        ),
        HdWallet() => HdSendWorkflow(
          prepare: tx.prepareHdSend,
          send: tx.sendHdTransaction,
          walletId: wallet.id,
          bech32Hrp: bech32Hrp,
        ),
      },
      eventBus: eventBus,
      walletId: wallet.id,
    );
  }

  @override
  Widget build(BuildContext context) => _InheritedSendScope(
    blocFactory: _blocFactory,
    child: widget.child,
  );
}

class _InheritedSendScope extends InheritedWidget {
  const _InheritedSendScope({
    required this.blocFactory,
    required super.child,
  });

  final SendBloc Function(Wallet) blocFactory;

  @override
  bool updateShouldNotify(_InheritedSendScope old) => false;
}
