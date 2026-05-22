import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_bloc.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/di/regtest_mining_scope.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_action.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_bloc.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_state.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_status.dart';
import 'package:bitcoin_wallet/feature/send/view/widget/broadcast_result.dart';
import 'package:bitcoin_wallet/feature/send/view/widget/send_form.dart';
import 'package:bitcoin_wallet/feature/send/view/widget/send_summary.dart';
import 'package:bitcoin_wallet/feature/send/view/widget/strategy_comparison.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart' show SendWorkflow;
import 'package:wallet/wallet.dart';

/// Two-step send flow: form → strategy comparison → confirm → broadcast.
///
/// [workflow] determines the coin-selection strategy. The caller is responsible
/// for building the correct [SendWorkflow] before pushing this screen.
class SendScreen extends StatefulWidget {
  const SendScreen({super.key, required this.wallet, required this.workflow});

  final Wallet wallet;
  final SendWorkflow workflow;

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _feeRateController = TextEditingController(text: '10');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _feeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<SendBloc>(
    create: (ctx) => SendBloc(
      workflow: widget.workflow,
      eventBus: AppScope.of(ctx).eventBus,
      walletId: widget.wallet.id,
    ),
    child: Scaffold(
      appBar: AppBar(title: const Text('Send')),
      body: ActionBlocConsumer<SendBloc, SendState, SendAction>(
        listener: (context, action) {
          switch (action) {
            case SendInsufficientFundsAction():
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Insufficient funds for any strategy')),
              );
            case SendFailedAction(:final exception):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(exception.toString())),
              );
            case SendUnexpectedFailedAction():
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Something went wrong. Please try again.')),
              );
          }
        },
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.status == SendStatus.idle || state.status == SendStatus.preparing)
                SendForm(
                  formKey: _formKey,
                  recipientController: _recipientController,
                  amountController: _amountController,
                  feeRateController: _feeRateController,
                  wallet: widget.wallet,
                  isLoading: state.status == SendStatus.preparing,
                ),
              if (state.status == SendStatus.awaitingConfirmation || state.status == SendStatus.sending) ...[
                StrategyComparison(state: state),
                const SizedBox(height: 24),
                SendSummary(state: state, wallet: widget.wallet),
              ],
              if (state.status == SendStatus.successful)
                RegtestMiningScope(
                  child: BlocProvider<RegtestMiningBloc>(
                    create: (ctx) => RegtestMiningScope.newBloc(ctx, widget.wallet.id),
                    child: BroadcastResult(
                      txid: state.txid,
                      changeAddress: state.changeAddress ?? '',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
