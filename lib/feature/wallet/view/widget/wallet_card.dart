import 'package:flutter/material.dart';
import 'package:wallet/wallet.dart';

/// A single wallet list tile.
class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.wallet,
    required this.onTap,
  });

  final Wallet wallet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (wallet) {
      NodeWallet() => 'Node',
      HdWallet() => 'HD',
    };
    final dateStr =
        '${wallet.createdAt.year}-${wallet.createdAt.month.toString().padLeft(2, '0')}-${wallet.createdAt.day.toString().padLeft(2, '0')}';

    return Semantics(
      label: 'Wallet ${wallet.name}, type $typeLabel',
      button: true,
      child: ListTile(
        title: Text(wallet.name),
        subtitle: Text(dateStr),
        trailing: Chip(label: Text(typeLabel)),
        onTap: onTap,
      ),
    );
  }
}
