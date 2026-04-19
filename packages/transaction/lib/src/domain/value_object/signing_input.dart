import 'package:shared_kernel/shared_kernel.dart';

/// Type-safe signing context for a single HD-wallet input.
///
/// Produced by [PrepareHdSendUseCase] and consumed by [TransactionSigner].
/// Carries everything the signer needs to derive the private key and build
/// the BIP-143 sighash for a P2WPKH input.
final class SigningInput {
  final String txid;
  final int vout;
  final Satoshi amountSat;

  /// The bech32 address that owns this output.
  final String address;

  /// BIP-32 child index used to derive the key for [address].
  final int derivationIndex;

  /// Address type — determines the scriptPubKey and sighash algorithm.
  final AddressType addressType;

  const SigningInput({
    required this.txid,
    required this.vout,
    required this.amountSat,
    required this.address,
    required this.derivationIndex,
    required this.addressType,
  });
}
