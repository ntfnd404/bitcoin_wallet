import 'package:address/address.dart';
import 'package:bitcoin_wallet/feature/address/view/screen/address_screen.dart';
import 'package:bitcoin_wallet/feature/wallet/view/screen/detail/wallet_detail_screen.dart';
import 'package:bitcoin_wallet/feature/wallet/view/screen/setup/create_wallet_screen.dart';
import 'package:bitcoin_wallet/feature/wallet/view/screen/setup/restore_wallet_screen.dart';
import 'package:bitcoin_wallet/feature/wallet/view/screen/setup/seed_phrase_screen.dart';
import 'package:flutter/material.dart';
import 'package:keys/keys.dart';
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

  const AppRouter._();

  /// Pushes [CreateWalletScreen] to the navigation stack.
  ///
  /// The screen shares the session [WalletBloc] and handles its own navigation
  /// based on wallet creation outcome (node vs HD wallet).
  static Future<void> toCreateWallet(BuildContext context) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: createWallet),
          builder: (_) => const CreateWalletScreen(),
        ),
      );

  /// Pushes [RestoreWalletScreen] to the navigation stack.
  ///
  /// The screen shares the session [WalletBloc] and handles its own navigation
  /// after wallet restoration completes.
  static Future<void> toRestoreWallet(BuildContext context) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: restoreWallet),
          builder: (_) => const RestoreWalletScreen(),
        ),
      );

  /// Pushes [WalletDetailScreen] for [wallet].
  static Future<void> toWalletDetail(
    BuildContext context,
    Wallet wallet,
  ) =>
      Navigator.push<void>(
        context,
        _buildDetailRoute(wallet),
      );

  /// Pushes [AddressScreen] for [addr].
  static Future<void> toAddress(BuildContext context, Address addr) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      settings: const RouteSettings(name: address),
      builder: (_) => AddressScreen(address: addr),
    ),
  );

  /// Pushes [SeedPhraseScreen] for viewing an existing seed.
  static Future<void> toSeedPhrase(
    BuildContext context,
    Mnemonic mnemonic,
    String walletId,
  ) => Navigator.push<void>(
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

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static MaterialPageRoute<void> _buildDetailRoute(Wallet wallet) =>
      MaterialPageRoute(
        settings: const RouteSettings(name: walletDetail),
        builder: (_) => WalletDetailScreen(wallet: wallet),
      );
}
