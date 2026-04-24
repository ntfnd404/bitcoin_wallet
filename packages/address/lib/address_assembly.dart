import 'package:address/src/application/address_generation_strategy.dart';
import 'package:address/src/application/generate_address_use_case.dart';
import 'package:address/src/application/hd_address_generation_strategy.dart';
import 'package:address/src/application/node_address_generation_strategy.dart';
import 'package:address/src/data/address_local_data_source_impl.dart';
import 'package:address/src/data/address_mapper.dart';
import 'package:address/src/data/address_repository_impl.dart';
import 'package:address/src/domain/data_sources/address_remote_data_source.dart';
import 'package:address/src/domain/repository/address_repository.dart';
import 'package:keys/keys.dart';
import 'package:shared_kernel/shared_kernel.dart';

final class AddressAssembly {
  final AddressRepository addressRepository;
  final GenerateAddressUseCase generateAddress;

  factory AddressAssembly({
    required SecureStorage storage,
    required AddressRemoteDataSource remoteDataSource,
    required SeedRepository seedRepository,
    required KeyDerivationService keyDerivationService,
  }) {
    final repository = AddressRepositoryImpl(
      localDataSource: AddressLocalDataSourceImpl(
        storage: storage,
        mapper: const AddressMapper(),
      ),
    );

    final List<AddressGenerationStrategy> strategies = [
      HdAddressGenerationStrategy(
        seedRepository: seedRepository,
        keyDerivationService: keyDerivationService,
        addressRepository: repository,
      ),
      NodeAddressGenerationStrategy(
        remoteDataSource: remoteDataSource,
        addressRepository: repository,
      ),
    ];

    return AddressAssembly._(
      addressRepository: repository,
      generateAddress: GenerateAddressUseCase(strategies: strategies),
    );
  }

  const AddressAssembly._({
    required this.addressRepository,
    required this.generateAddress,
  });
}
