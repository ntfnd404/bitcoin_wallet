import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays a single address with copy action, QR placeholder, and path info.
class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key, required this.address});

  final Address address;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Address')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              address.value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
            const SizedBox(height: 24),
            Semantics(
              label: 'Copy address to clipboard',
              button: true,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: address.value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address copied')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy'),
              ),
            ),
            const SizedBox(height: 32),
            const Text('[QR]', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 24),
            Text(address.derivationPath ?? 'Managed by Bitcoin Core'),
          ],
        ),
      ),
    ),
  );
}
