import 'package:bitcoin_wallet/feature/regtest_mining/bloc/regtest_mining_status.dart';

final class RegtestMiningState {
  final RegtestMiningStatus status;

  const RegtestMiningState({
    this.status = RegtestMiningStatus.idle,
  });

  RegtestMiningState copyWith({RegtestMiningStatus? status}) => RegtestMiningState(status: status ?? this.status);
}
