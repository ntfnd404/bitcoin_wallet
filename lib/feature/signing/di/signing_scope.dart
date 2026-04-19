import 'package:bitcoin_wallet/core/di/app_scope.dart';
import 'package:bitcoin_wallet/feature/signing/send/bloc/signing_bloc.dart';
import 'package:bitcoin_wallet/feature/signing/xpub/bloc/xpub_bloc.dart';
import 'package:flutter/widgets.dart';

/// Feature-scoped DI entry point for xpub display and HD transaction signing.
///
/// Exposes factory methods for [XpubBloc] and [SigningBloc].
/// Use cases come from [KeysAssembly], [AddressAssembly], and
/// [TransactionAssembly] via [AppScope].
class SigningScope extends StatefulWidget {
  const SigningScope({super.key, required this.child});

  /// Creates a new [XpubBloc] wired with use cases from the nearest
  /// [SigningScope] ancestor.
  static XpubBloc newXpubBloc(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<_InheritedSigningScope>();
    if (scope == null) throw StateError('SigningScope not found in widget tree');

    return scope.newXpubBloc();
  }

  /// Creates a new [SigningBloc] wired with use cases from the nearest
  /// [SigningScope] ancestor.
  static SigningBloc newSigningBloc(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<_InheritedSigningScope>();
    if (scope == null) throw StateError('SigningScope not found in widget tree');

    return scope.newSigningBloc();
  }

  final Widget child;

  @override
  State<SigningScope> createState() => _SigningScopeState();
}

class _SigningScopeState extends State<SigningScope> {
  late final XpubBloc Function() _xpubFactory;
  late final SigningBloc Function() _signingFactory;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = AppScope.of(context);

    _xpubFactory = () => XpubBloc(getXpub: deps.keys.getXpub);
    _signingFactory = () => SigningBloc(
          addressRepository: deps.address.addressRepository,
          scanUtxos: deps.transaction.scanUtxos,
          signTransaction: deps.keys.signTransaction,
          broadcastTransaction: deps.transaction.broadcastTransaction,
        );
  }

  @override
  Widget build(BuildContext context) => _InheritedSigningScope(
        newXpubBloc: _xpubFactory,
        newSigningBloc: _signingFactory,
        child: widget.child,
      );
}

class _InheritedSigningScope extends InheritedWidget {
  const _InheritedSigningScope({
    required this.newXpubBloc,
    required this.newSigningBloc,
    required super.child,
  });

  final XpubBloc Function() newXpubBloc;
  final SigningBloc Function() newSigningBloc;

  @override
  bool updateShouldNotify(_InheritedSigningScope old) => false;
}
