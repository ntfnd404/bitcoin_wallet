import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// Feature-scoped DI entry point for the send flow.
///
/// Reads use cases from [AppDependencies.transaction] and exposes workflow
/// factories via [buildWorkflow] and [buildPinnedWorkflow]. The actual
/// [SendBloc] is created inside [SendScreen] using [BlocProvider].
class SendScope extends StatefulWidget {
  const SendScope({super.key, required this.child});

  /// Builds the correct [SendWorkflow] for auto coin-selection send.
  static SendWorkflow buildWorkflow(BuildContext context, Wallet wallet) {
    final scope = context.getInheritedWidgetOfExactType<_InheritedSendScope>();
    if (scope == null) throw StateError('SendScope not found in widget tree');

    return scope.workflowFactory(wallet);
  }

  /// Builds a [SendWorkflow] that uses the given [pinnedInputs] for a node wallet.
  static SendWorkflow buildPinnedWorkflow(
    BuildContext context,
    NodeWallet wallet,
    List<Utxo> pinnedInputs,
  ) {
    final scope = context.getInheritedWidgetOfExactType<_InheritedSendScope>();
    if (scope == null) throw StateError('SendScope not found in widget tree');

    return scope.pinnedWorkflowFactory(wallet, pinnedInputs);
  }

  final Widget child;

  @override
  State<SendScope> createState() => _SendScopeState();
}

class _SendScopeState extends State<SendScope> {
  late final SendWorkflow Function(Wallet) _workflowFactory;
  late final SendWorkflow Function(NodeWallet, List<Utxo>) _pinnedWorkflowFactory;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);
    final tx = deps.transaction;
    final bech32Hrp = deps.network.bech32Hrp;

    _workflowFactory = (wallet) => switch (wallet) {
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
    };

    _pinnedWorkflowFactory = (wallet, pinnedInputs) => NodePinnedSendWorkflow(
      prepare: tx.prepareNodePinnedSend,
      send: tx.sendNodeTransaction,
      walletName: wallet.name,
      pinnedInputs: pinnedInputs,
    );
  }

  @override
  Widget build(BuildContext context) => _InheritedSendScope(
    workflowFactory: _workflowFactory,
    pinnedWorkflowFactory: _pinnedWorkflowFactory,
    child: widget.child,
  );
}

class _InheritedSendScope extends InheritedWidget {
  const _InheritedSendScope({
    required this.workflowFactory,
    required this.pinnedWorkflowFactory,
    required super.child,
  });

  final SendWorkflow Function(Wallet) workflowFactory;
  final SendWorkflow Function(NodeWallet, List<Utxo>) pinnedWorkflowFactory;

  @override
  bool updateShouldNotify(_InheritedSendScope old) => false;
}
