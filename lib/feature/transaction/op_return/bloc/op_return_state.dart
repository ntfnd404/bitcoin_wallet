import 'package:bitcoin_wallet/feature/transaction/op_return/bloc/op_return_status.dart';

final class OpReturnState {
  final OpReturnStatus status;

  /// Current UTF-8 text entered by the user.
  final String text;

  /// Full OP_RETURN scriptPubKey hex preview (includes 6a opcode + push encoding).
  /// Empty when [text] encodes to 0 or >80 bytes.
  final String hexPreview;

  /// UTF-8 byte count of [text].
  final int byteCount;

  /// Fee rate the user selected (sat/vbyte).
  final int feeRateSatPerVbyte;

  /// True when [byteCount] is between 1 and 80 inclusive.
  final bool isValid;

  const OpReturnState({
    this.status = OpReturnStatus.idle,
    this.text = '',
    this.hexPreview = '',
    this.byteCount = 0,
    this.feeRateSatPerVbyte = 1,
    this.isValid = false,
  });

  OpReturnState copyWith({
    OpReturnStatus? status,
    String? text,
    String? hexPreview,
    int? byteCount,
    int? feeRateSatPerVbyte,
    bool? isValid,
  }) => OpReturnState(
    status: status ?? this.status,
    text: text ?? this.text,
    hexPreview: hexPreview ?? this.hexPreview,
    byteCount: byteCount ?? this.byteCount,
    feeRateSatPerVbyte: feeRateSatPerVbyte ?? this.feeRateSatPerVbyte,
    isValid: isValid ?? this.isValid,
  );
}
