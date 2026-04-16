import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_bloc.dart';
import 'package:bitcoin_wallet/feature/address/domain/domain.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// Feature-scoped DI entry point for the address feature.
///
/// Composition root: creates all address use cases from [AppDependencies]
/// and exposes a factory for screen-level [AddressBloc] instances via
/// [_InheritedAddressScope].
///
/// Use cases are created once in [State.initState] and reused across all
/// [AddressBloc] instances. The router calls [newAddressBloc] to create
/// a fresh [AddressBloc] per [WalletDetailScreen].
class AddressScope extends StatefulWidget {
  const AddressScope({
    super.key,
    required this.child,
  });

  /// Creates a new [AddressBloc] wired with use cases from the nearest
  /// [AddressScope] ancestor.
  static AddressBloc newAddressBloc(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_InheritedAddressScope>();
    if (scope == null) throw StateError('AddressScope not found in widget tree');

    return scope.newAddressBloc();
  }

  final Widget child;

  @override
  State<AddressScope> createState() => _AddressScopeState();
}

class _AddressScopeState extends State<AddressScope> {
  // Use cases — address
  late final AddressRepository _addressRepository;
  late final GenerateAddressUseCase _generateAddress;
  bool _initialized = false;

  AddressBloc _newAddressBloc() => AddressBloc(
    addressRepository: _addressRepository,
    generateAddress: _generateAddress,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final dependencies = AppScope.of(context);

    _addressRepository = dependencies.addressRepository;
    _generateAddress = GenerateAddressUseCase(
      strategies: [
        NodeAddressGenerationStrategy(
          remoteDataSource: dependencies.bitcoinCoreRemoteDataSource,
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

  @override
  Widget build(BuildContext context) => _InheritedAddressScope(
    newAddressBloc: _newAddressBloc,
    child: widget.child,
  );
}

class _InheritedAddressScope extends InheritedWidget {
  const _InheritedAddressScope({
    required this.newAddressBloc,
    required super.child,
  });

  final AddressBloc Function() newAddressBloc;

  @override
  bool updateShouldNotify(_InheritedAddressScope old) => false;
}
