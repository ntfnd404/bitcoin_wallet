import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_action.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_bloc.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/bloc/signing_state.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/di/manual_utxo_scope.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/view/widget/signing_broadcast_result.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/view/widget/signing_send_form.dart';
import 'package:bitcoin_wallet/feature/signing/manual_utxo/view/widget/utxo_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/wallet.dart';

/// HD wallet sign-and-broadcast demo.
///
/// Scans the UTXO set for stored native SegWit addresses, then lets the user
/// specify a recipient and amount to create, sign, and broadcast a transaction.
class SigningDemoScreen extends StatefulWidget {
  const SigningDemoScreen({super.key, required this.wallet});

  final Wallet wallet;

  @override
  State<SigningDemoScreen> createState() => _SigningDemoScreenState();
}

class _SigningDemoScreenState extends State<SigningDemoScreen> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<SigningBloc>(
    create: (ctx) => ManualUtxoScope.newSigningBloc(ctx),
    child: Scaffold(
      appBar: AppBar(title: const Text('Sign & Send')),
      body: ActionBlocConsumer<SigningBloc, SigningState, SigningAction>(
        listener: (context, action) {
          switch (action) {
            case SigningNoAddressesFoundAction():
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No native SegWit addresses found. Generate some first.')),
              );
            case SigningNoUtxosFoundAction():
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No UTXOs to spend. Scan first.')),
              );
            case SigningKeysFailedAction(:final exception):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(exception.toString())),
              );
            case SigningTransactionFailedAction(:final exception):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(exception.toString())),
              );
          }
        },
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UtxoSection(
                walletId: widget.wallet.id,
                state: state,
              ),
              if (state.status == SigningStatus.scanned && state.utxos.isNotEmpty) ...[
                const SizedBox(height: 24),
                SigningSendForm(
                  formKey: _formKey,
                  recipientController: _recipientController,
                  amountController: _amountController,
                  walletId: widget.wallet.id,
                ),
              ],
              if (state.status == SigningStatus.broadcasted && state.txid != null) ...[
                const SizedBox(height: 24),
                SigningBroadcastResult(state: state),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
