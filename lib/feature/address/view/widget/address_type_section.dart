import 'package:address/address.dart';
import 'package:flutter/material.dart';
import 'package:shared_kernel/shared_kernel.dart';

const _typeLabels = {
  AddressType.legacy: 'Legacy (P2PKH)',
  AddressType.wrappedSegwit: 'Wrapped SegWit (P2SH-P2WPKH)',
  AddressType.nativeSegwit: 'Native SegWit (P2WPKH)',
  AddressType.taproot: 'Taproot (P2TR)',
};

/// Renders the header and address list for a single [AddressType].
class AddressTypeSection extends StatelessWidget {
  const AddressTypeSection({
    super.key,
    required this.type,
    required this.addresses,
    required this.isGenerating,
    required this.onGenerate,
    required this.onAddressSelected,
  });

  final AddressType type;
  final List<Address> addresses;

  /// True when [AddressBloc] status is [AddressStatus.generating].
  final bool isGenerating;

  final VoidCallback onGenerate;
  final void Function(Address address) onAddressSelected;

  @override
  Widget build(BuildContext context) {
    final label = _typeLabels[type] ?? type.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...addresses.map(
          (address) => Semantics(
            label: 'Address ${address.value}',
            button: true,
            child: ListTile(
              title: Text(
                '${address.value.substring(0, address.value.length > 12 ? 12 : address.value.length)}...',
              ),
              onTap: () => onAddressSelected(address),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Semantics(
            label: 'Generate $label address',
            button: true,
            child: OutlinedButton(
              onPressed: isGenerating ? null : onGenerate,
              child: isGenerating
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate'),
            ),
          ),
        ),
      ],
    );
  }
}
