import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_bloc.dart';
import 'package:bitcoin_wallet/feature/regtest_mining/di/regtest_mining_scope.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_action.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_bloc.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_state.dart';
import 'package:bitcoin_wallet/feature/send/bloc/send_status.dart';
import 'package:bitcoin_wallet/feature/send/di/send_scope.dart';
import 'package:bitcoin_wallet/feature/send/view/widget/broadcast_result.dart';
import 'package:bitcoin_wallet/feature/send/view/widget/send_form.dart';
import 'package:bitcoin_wallet/feature/send/view/widget/send_summary.dart';
import 'package:bitcoin_wallet/feature/send/view/widget/strategy_comparison.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// Two-step send flow: form → strategy comparison → confirm → broadcast.
class SendScreen extends StatefulWidget {
  const SendScreen({
    super.key,
    required this.wallet,
    this.pinned = const [],
  });

  final Wallet wallet;
  final List<Utxo> pinned;

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
    create: (ctx) => SendScope.newBloc(ctx, widget.wallet, pinned: widget.pinned),
    child: Scaffold(
      appBar: AppBar(title: const Text('Send')),
      body: ActionBlocConsumer<SendBloc, SendState, SendAction>(
        actionListener: (context, _, action) {
          switch (action) {
            case SendInsufficientFundsAction():
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No spendable UTXOs. Go to Wallet Detail → Mine block to fund the wallet first.',
                  ),
                  duration: Duration(seconds: 6),
                ),
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
              if (state.status != SendStatus.successful)
                SendForm(
                  formKey: _formKey,
                  recipientController: _recipientController,
                  amountController: _amountController,
                  feeRateController: _feeRateController,
                  wallet: widget.wallet,
                  isLoading: state.status == SendStatus.preparing,
                  canSend: state.status == SendStatus.awaitingConfirmation,
                ),
              if (state.status == SendStatus.awaitingConfirmation || state.status == SendStatus.sending) ...[
                const SizedBox(height: 24),
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
