import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// Feature-scoped DI factory for the send flow.
///
/// Reads [TransactionAssembly] from [AppScope] and constructs a [SendBloc]
/// wired to the correct [SendWorkflow] for the given wallet and input set.
final class SendScope {
  SendScope._();

  static SendBloc newBloc(
    BuildContext context,
    Wallet wallet, {
    List<Utxo>? pinned,
  }) {
    final deps = AppScope.of(context);
    final tx = deps.transaction;
    final workflow = (pinned != null && pinned.isNotEmpty)
        ? tx.buildPinnedSendWorkflow(wallet, pinned)
        : tx.buildAutoSendWorkflow(wallet);

    return SendBloc(
      workflow: workflow,
      eventBus: deps.eventBus,
      walletId: wallet.id,
    );
  }
}
