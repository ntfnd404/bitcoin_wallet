/// Generic fetch operation status shared across list BLoCs.
///
/// Domain-specific statuses (e.g. [WalletStatus], [AddressStatus]) with
/// feature-specific values (creating, generating, …) stay separate.
enum FetchStatus { initial, loading, loaded, error }
