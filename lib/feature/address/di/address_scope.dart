import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/address/bloc/address_bloc.dart';
import 'package:flutter/widgets.dart';

/// Feature-scoped DI entry point for the address feature.
///
/// Composition root: exposes a factory for screen-level [AddressBloc]
/// instances via [_InheritedAddressScope].
///
/// Use cases come from [AddressAssembly]. The router calls [newAddressBloc]
/// to create a fresh [AddressBloc] per [WalletDetailScreen].
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
  late final AddressBloc Function() _blocFactory;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);
    final addressAssembly = deps.address;

    _blocFactory = () => AddressBloc(
      addressRepository: addressAssembly.addressRepository,
      generateAddress: addressAssembly.generateAddress,
    );
  }

  @override
  Widget build(BuildContext context) => _InheritedAddressScope(
    newAddressBloc: _blocFactory,
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
