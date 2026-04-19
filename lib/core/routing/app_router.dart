import 'package:address/address.dart';
import 'package:bitcoin_wallet/feature/address/view/screen/address_screen.dart';
import 'package:bitcoin_wallet/feature/send/view/screen/send_screen.dart';
import 'package:bitcoin_wallet/feature/signing/send/view/screen/signing_demo_screen.dart';
import 'package:bitcoin_wallet/feature/signing/xpub/view/screen/xpub_screen.dart';
import 'package:bitcoin_wallet/feature/transaction/detail/view/screen/transaction_detail_screen.dart';
import 'package:bitcoin_wallet/feature/transaction/list/view/screen/transaction_list_screen.dart';
import 'package:bitcoin_wallet/feature/utxo/view/screen/utxo_detail_screen.dart';
import 'package:bitcoin_wallet/feature/utxo/view/screen/utxo_list_screen.dart';
import 'package:bitcoin_wallet/feature/wallet/view/screen/detail/wallet_detail_screen.dart';
import 'package:bitcoin_wallet/feature/wallet/view/screen/setup/create_wallet_screen.dart';
import 'package:bitcoin_wallet/feature/wallet/view/screen/setup/restore_wallet_screen.dart';
import 'package:bitcoin_wallet/feature/wallet/view/screen/setup/seed_phrase_screen.dart';
import 'package:flutter/material.dart';
import 'package:keys/keys.dart';
import 'package:transaction/transaction.dart';
import 'package:wallet/wallet.dart';

/// Centralised navigation helpers for the wallet feature.
///
/// All navigation is imperative (`Navigator.push` / `pushReplacement` / `pop`).
/// Route name constants serve as documentation aids for future deep-linking.
final class AppRouter {
  static const String walletList = '/';
  static const String createWallet = '/wallet/create';
  static const String seedPhrase = '/wallet/seed';
  static const String restoreWallet = '/wallet/restore';
  static const String walletDetail = '/wallet/detail';
  static const String address = '/wallet/address';
  static const String transactionList = '/wallet/transactions';
  static const String transactionDetail = '/wallet/transactions/detail';
  static const String utxoList = '/wallet/utxos';
  static const String utxoDetail = '/wallet/utxos/detail';
  static const String xpub = '/wallet/xpub';
  static const String signingDemo = '/wallet/signing';
  static const String send = '/wallet/send';

  const AppRouter._();

  static Future<void> toCreateWallet(BuildContext context) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: createWallet),
          builder: (_) => const CreateWalletScreen(),
        ),
      );

  static Future<void> toRestoreWallet(BuildContext context) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: restoreWallet),
          builder: (_) => const RestoreWalletScreen(),
        ),
      );

  static Future<void> toWalletDetail(
    BuildContext context,
    Wallet wallet,
  ) =>
      Navigator.push<void>(
        context,
        _buildDetailRoute(wallet),
      );

  static Future<void> toAddress(BuildContext context, Address addr) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: address),
          builder: (_) => AddressScreen(address: addr),
        ),
      );

  static Future<void> toSeedPhrase(
    BuildContext context,
    Mnemonic mnemonic,
    String walletId,
  ) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: seedPhrase),
          builder: (_) => SeedPhraseScreen(
            mnemonic: mnemonic,
            walletId: walletId,
            onConfirmed: () => Navigator.pop(context),
          ),
        ),
      );

  static Future<void> toTransactionList(
    BuildContext context,
    Wallet wallet,
  ) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: transactionList),
          builder: (_) => TransactionListScreen(wallet: wallet),
        ),
      );

  static Future<void> toTransactionDetail(
    BuildContext context,
    Transaction transaction,
    Wallet wallet,
  ) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: transactionDetail),
          builder: (_) => TransactionDetailScreen(
            transaction: transaction,
            wallet: wallet,
          ),
        ),
      );

  static Future<void> toUtxoList(BuildContext context, Wallet wallet) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: utxoList),
          builder: (_) => UtxoListScreen(wallet: wallet),
        ),
      );

  static Future<void> toUtxoDetail(BuildContext context, Utxo utxo) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: utxoDetail),
          builder: (_) => UtxoDetailScreen(utxo: utxo),
        ),
      );

  static Future<void> toXpub(BuildContext context, Wallet wallet) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: xpub),
          builder: (_) => XpubScreen(wallet: wallet),
        ),
      );

  static Future<void> toSigningDemo(BuildContext context, Wallet wallet) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: signingDemo),
          builder: (_) => SigningDemoScreen(wallet: wallet),
        ),
      );

  static Future<void> toSend(BuildContext context, Wallet wallet) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: send),
          builder: (_) => SendScreen(wallet: wallet),
        ),
      );

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static MaterialPageRoute<void> _buildDetailRoute(Wallet wallet) =>
      MaterialPageRoute(
        settings: const RouteSettings(name: walletDetail),
        builder: (_) => WalletDetailScreen(wallet: wallet),
      );
}
