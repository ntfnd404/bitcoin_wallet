import 'package:action_bloc/action_bloc.dart';
import 'package:bitcoin_wallet/common/widgets/copyable_text.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_action.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_bloc.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_state.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/di/op_return_scope.dart';
import 'package:bitcoin_wallet/feature/transaction/op_return/view/widget/op_return_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/wallet.dart';

/// Screen for constructing and broadcasting an OP_RETURN transaction.
///
/// Node wallet only. Allows the user to embed up to 80 bytes of UTF-8 data
/// on-chain as an unspendable OP_RETURN output.
class OpReturnScreen extends StatelessWidget {
  const OpReturnScreen({super.key, required this.wallet});

  final NodeWallet wallet;

  @override
  Widget build(BuildContext context) => BlocProvider<OpReturnBloc>(
    create: (_) => OpReturnScope.newBloc(context, wallet),
    child: Scaffold(
      appBar: AppBar(title: const Text('OP_RETURN Transaction')),
      body: ActionBlocConsumer<OpReturnBloc, OpReturnState, OpReturnAction>(
        actionListener: (context, _, action) {
          switch (action) {
            case OpReturnBroadcastedAction(:final txid):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Broadcast successful!'),
                      const SizedBox(height: 4),
                      CopyableText(text: txid),
                    ],
                  ),
                  duration: const Duration(seconds: 6),
                ),
              );
            case OpReturnBroadcastFailedAction(:final message):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            case OpReturnUnexpectedFailedAction():
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('An unexpected error occurred.')),
              );
          }
        },
        builder: (context, state) => const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: OpReturnForm(),
        ),
      ),
    ),
  );
}
