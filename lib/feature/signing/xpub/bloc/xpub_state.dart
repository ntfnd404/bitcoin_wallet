import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:keys/keys.dart';
import 'package:shared_kernel/shared_kernel.dart';

final class XpubState {
  final FetchStatus status;
  final Map<AddressType, AccountXpub> xpubs;
  final String? errorMessage;

  const XpubState({
    this.status = FetchStatus.initial,
    this.xpubs = const {},
    this.errorMessage,
  });

  XpubState copyWith({
    FetchStatus? status,
    Map<AddressType, AccountXpub>? xpubs,
    String? errorMessage,
  }) => XpubState(
    status: status ?? this.status,
    xpubs: xpubs ?? this.xpubs,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
