import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/src/domain/value_object/coin_selection_strategy_result.dart';
import 'package:transaction/src/domain/value_object/signing_context.dart';

/// Signs the selected coin set and broadcasts the resulting transaction.
///
/// Each wallet flavour has its own implementation that interprets the
/// runtime [SigningContext] type produced by the originating `UtxoSource`:
/// - Node Wallet (`NodeRpcSigner`) — signs server-side via Bitcoin Core RPC.
/// - HD Wallet (`HdInAppSigner`) — signs in-app via the keys-package signer.
///
/// Implementations must reject a mismatched [SigningContext] runtime type
/// with a typed [TransactionSigningException] **before** any side effect
/// (no RPC call, no key derivation, no logging of signing material).
///
/// Returns the txid of the broadcast transaction.
abstract interface class Signer {
  Future<String> signAndBroadcast({
    required CoinSelectionStrategyResult strategy,
    required SigningContext signingContext,
    required String recipientAddress,
    required Satoshi amountSat,
    required String changeAddress,
  });
}
