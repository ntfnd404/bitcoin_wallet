import 'package:bitcoin_wallet/core/routing/app_router.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_bloc.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_event.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_state.dart';
import 'package:bitcoin_wallet/feature/address/di/address_scope.dart';
import 'package:bitcoin_wallet/feature/address/view/widget/address_type_section.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_bloc.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_event.dart';
import 'package:bitcoin_wallet/feature/wallet/bloc/wallet_state.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows addresses for a single wallet grouped by [AddressType].
///
/// Creates its own [AddressBloc] via [AddressScope] factory — each instance
/// owns an isolated address BLoC with its own lifecycle.
/// Navigates to [AddressScreen] and [SeedPhraseScreen] via [AppRouter].
class WalletDetailScreen extends StatefulWidget {
  const WalletDetailScreen({
    super.key,
    required this.wallet,
  });

  final Wallet wallet;

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  late final AddressBloc _addressBloc;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _addressBloc = AddressScope.newAddressBloc(context);
      _addressBloc.add(AddressListRequested(wallet: widget.wallet));
    }
  }

  @override
  void dispose() {
    _addressBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider<AddressBloc>.value(
    value: _addressBloc,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.wallet.name),
        actions: [
          if (widget.wallet.isHd)
            Semantics(
              label: 'View seed phrase',
              button: true,
              child: TextButton(
                onPressed: () {
                  context.read<WalletBloc>().add(SeedViewRequested(walletId: widget.wallet.id));
                },
                child: const Text('View Seed'),
              ),
            ),
        ],
      ),
      body: BlocListener<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state.status == WalletStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Unknown error')),
            );
          }
          if (state.status == WalletStatus.awaitingSeedConfirmation) {
            final mnemonic = state.pendingMnemonic;
            if (mnemonic != null) {
              AppRouter.toSeedPhrase(context, mnemonic, widget.wallet.id);
            }
          }
        },
        child: BlocConsumer<AddressBloc, AddressState>(
          listener: (context, state) {
            if (state.status == AddressStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage ?? 'Unknown error')),
              );
            }
          },
          builder: (context, state) {
            if (state.status == AddressStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final isGenerating = state.status == AddressStatus.generating;

            return ListView(
              children: AddressType.values.map((type) {
                final filtered = state.addresses.where((a) => a.type == type).toList();

                return AddressTypeSection(
                  type: type,
                  addresses: filtered,
                  isGenerating: isGenerating,
                  onGenerate: () => context.read<AddressBloc>().add(
                    AddressGenerateRequested(wallet: widget.wallet, type: type),
                  ),
                  onAddressSelected: (addr) => AppRouter.toAddress(context, addr),
                );
              }).toList(),
            );
          },
        ),
      ),
    ),
  );

}
