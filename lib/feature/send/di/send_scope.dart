import 'package:bitcoin_wallet/core/constants/app_constants.dart';
import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:wallet/wallet.dart';

/// Feature-scoped DI entry point for the send flow.
///
/// Exposes a factory method for [SendBloc], wiring the correct prepare/send
/// use cases based on [Wallet.type].
class SendScope extends StatefulWidget {
  const SendScope({super.key, required this.child});

  /// Creates a new [SendBloc] for [wallet], wired with use cases from the
  /// nearest [SendScope] ancestor.
  static SendBloc newSendBloc(BuildContext context, Wallet wallet) {
    final scope = context.getInheritedWidgetOfExactType<_InheritedSendScope>();
    if (scope == null) throw StateError('SendScope not found in widget tree');

    return scope.newSendBloc(wallet);
  }

  final Widget child;

  @override
  State<SendScope> createState() => _SendScopeState();
}

class _SendScopeState extends State<SendScope> {
  late final SendBloc Function(Wallet) _factory;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);
    final tx = deps.transaction;
    final bech32Hrp = AppConstants.network.bech32Hrp;

    _factory = (wallet) => wallet is NodeWallet
        ? SendBloc(
            wallet: wallet,
            prepareNode: tx.prepareNodeSend,
            sendNode: tx.sendNodeTransaction,
            blockGeneration: tx.blockGeneration,
            bech32Hrp: bech32Hrp,
          )
        : SendBloc(
            wallet: wallet,
            prepareHd: tx.prepareHdSend,
            sendHd: tx.sendHdTransaction,
            blockGeneration: tx.blockGeneration,
            bech32Hrp: bech32Hrp,
          );
  }

  @override
  Widget build(BuildContext context) => _InheritedSendScope(
    newSendBloc: _factory,
    child: widget.child,
  );
}

class _InheritedSendScope extends InheritedWidget {
  const _InheritedSendScope({
    required this.newSendBloc,
    required super.child,
  });

  final SendBloc Function(Wallet) newSendBloc;

  @override
  bool updateShouldNotify(_InheritedSendScope old) => false;
}
