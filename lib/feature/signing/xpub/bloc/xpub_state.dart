import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:keys/keys.dart';
import 'package:shared_kernel/shared_kernel.dart';

final class XpubState {
  final FetchStatus status;
  final Map<AddressType, AccountXpub> xpubs;

  /// Typed failure for persistent page-level error render.
  final KeysException? failure;

  const XpubState({
    this.status = FetchStatus.idle,
    this.xpubs = const {},
    this.failure,
  });

  XpubState copyWith({
    FetchStatus? status,
    Map<AddressType, AccountXpub>? xpubs,
    KeysException? failure,
    bool clearFailure = false,
  }) => XpubState(
    status: status ?? this.status,
    xpubs: xpubs ?? this.xpubs,
    failure: clearFailure ? null : (failure ?? this.failure),
  );
}
