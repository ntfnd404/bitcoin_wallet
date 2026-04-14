import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_bloc.dart';
import 'package:bitcoin_wallet/feature/address/domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Feature-scoped DI entry point for the address feature.
///
/// Composition root: creates all address use cases from [AppDependencies]
/// and wires them to address-specific [AddressBloc] instances.
///
/// Since [AddressBloc] is wallet-specific, it is created on-demand by
/// the router and wrapped in a [BlocProvider] per screen.
class AddressScope extends StatefulWidget {
  const AddressScope({
    super.key,
    required this.child,
  });

  static AddressBloc newAddressBloc(BuildContext context) {
    final state = context.findAncestorStateOfType<_AddressScopeState>();
    if (state == null) {
      throw StateError('AddressScope not found in widget tree');
    }

    return state._newAddressBloc();
  }

  final Widget child;

  @override
  State<AddressScope> createState() => _AddressScopeState();
}

class _AddressScopeState extends State<AddressScope> {
  // Use cases — address
  late final GetAddressesUseCase _getAddresses;
  late final GenerateAddressUseCase _generateAddress;

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);

    // Create address use cases
    _getAddresses = GetAddressesUseCase(addressRepository: dependencies.addressRepository);

    _generateAddress = GenerateAddressUseCase(
      strategies: [
        NodeAddressGenerationStrategy(
          gateway: dependencies.bitcoinCoreGateway,
          addressRepository: dependencies.addressRepository,
        ),
        HdAddressGenerationStrategy(
          seedRepository: dependencies.seedRepository,
          keyDerivationService: dependencies.keyDerivationService,
          addressRepository: dependencies.addressRepository,
        ),
      ],
    );
  }

  AddressBloc _newAddressBloc() => AddressBloc(
    getAddresses: _getAddresses,
    generateAddress: _generateAddress,
  );

  @override
  Widget build(BuildContext context) => widget.child;
}
