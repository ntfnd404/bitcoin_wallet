import 'package:bitcoin_wallet/common/fetch_status.dart';
import 'package:shared_kernel/shared_kernel.dart';
import 'package:transaction/transaction.dart';

final class UtxoPickerState {
  final List<Utxo> utxos;

  /// String keys of selected UTXOs: `"$txid:$vout"`.
  final Set<String> selectedKeys;

  final int feeRateSatPerVbyte;

  /// Sum of selected UTXO amounts.
  final Satoshi inputSumSat;

  /// Estimated fee for selected inputs (2 outputs assumed).
  final Satoshi estimatedFeeSat;

  /// Estimated change = max(0, inputSum - fee).
  final Satoshi estimatedChangeSat;

  final FetchStatus status;

  /// True when at least one UTXO is selected.
  bool get canProceed => selectedKeys.isNotEmpty;

  /// UTXOs whose keys are in [selectedKeys].
  List<Utxo> get selectedUtxos => utxos.where((u) => selectedKeys.contains(_keyFor(u))).toList();

  const UtxoPickerState({
    this.utxos = const [],
    this.selectedKeys = const {},
    this.feeRateSatPerVbyte = 1,
    this.inputSumSat = Satoshi.zero,
    this.estimatedFeeSat = Satoshi.zero,
    this.estimatedChangeSat = Satoshi.zero,
    this.status = FetchStatus.idle,
  });

  UtxoPickerState copyWith({
    List<Utxo>? utxos,
    Set<String>? selectedKeys,
    int? feeRateSatPerVbyte,
    Satoshi? inputSumSat,
    Satoshi? estimatedFeeSat,
    Satoshi? estimatedChangeSat,
    FetchStatus? status,
  }) => UtxoPickerState(
    utxos: utxos ?? this.utxos,
    selectedKeys: selectedKeys ?? this.selectedKeys,
    feeRateSatPerVbyte: feeRateSatPerVbyte ?? this.feeRateSatPerVbyte,
    inputSumSat: inputSumSat ?? this.inputSumSat,
    estimatedFeeSat: estimatedFeeSat ?? this.estimatedFeeSat,
    estimatedChangeSat: estimatedChangeSat ?? this.estimatedChangeSat,
    status: status ?? this.status,
  );
}

/// Stable key for a UTXO used in [UtxoPickerState.selectedKeys].
String _keyFor(Utxo u) => '${u.txid}:${u.vout}';
