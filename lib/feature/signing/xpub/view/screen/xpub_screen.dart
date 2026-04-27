import 'package:bitcoin_wallet/common/extensions/address_type_display.dart';
import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:bitcoin_wallet/common/widgets/detail_section.dart';
import 'package:bitcoin_wallet/feature/signing/xpub/bloc/xpub_bloc.dart';
import 'package:bitcoin_wallet/feature/signing/xpub/bloc/xpub_event.dart';
import 'package:bitcoin_wallet/feature/signing/xpub/bloc/xpub_state.dart';
import 'package:bitcoin_wallet/feature/signing/xpub/di/xpub_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:wallet/wallet.dart';

/// Displays the account-level xpub for every address type of an HD wallet.
///
/// Each xpub is shown with its BIP32 derivation path and can be copied
/// to the clipboard via [CopyableText].
class XpubScreen extends StatelessWidget {
  const XpubScreen({super.key, required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) => BlocProvider<XpubBloc>(
    create: (ctx) => XpubScope.newXpubBloc(ctx)..add(XpubLoadRequested(walletId: wallet.id)),
    child: Scaffold(
      appBar: AppBar(title: const Text('Account xpubs')),
      body: BlocBuilder<XpubBloc, XpubState>(
        builder: (context, state) {
          if (state.status == FetchStatus.loading || state.status == FetchStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == FetchStatus.error) {
            return Center(
              child: Text(state.errorMessage ?? 'Unknown error'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: AddressType.values.map((type) {
              final xpub = state.xpubs[type];
              if (xpub == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailSection(
                      title: type.fullLabel,
                      child: CopyableText(text: xpub.xpub),
                    ),
                    const SizedBox(height: 8),
                    DetailSection(
                      title: 'Derivation path',
                      child: Text(
                        xpub.derivationPath,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    ),
  );
}
