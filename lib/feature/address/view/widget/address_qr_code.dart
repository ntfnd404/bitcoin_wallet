import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renders a QR code for a Bitcoin address string.
///
/// [address] must be the raw address value (no URI prefix).
/// [size] defaults to 220 logical pixels.
final class AddressQrCode extends StatelessWidget {
  const AddressQrCode({
    super.key,
    required this.address,
    this.size = 220,
  });

  final String address;
  final double size;

  @override
  Widget build(BuildContext context) => QrImageView(
    data: address,
    size: size,
    semanticsLabel: 'QR code for address $address',
  );
}
