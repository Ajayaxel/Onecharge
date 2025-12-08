import '../datasources/model_remote_data_source.dart';
import '../models/submodel.dart';

class ModelRepository {
  ModelRepository({
    ModelRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? ModelRemoteDataSource();

  final ModelRemoteDataSource _remoteDataSource;

  Future<List<SubModel>> getModelsByBrand({
    required int brandId,
    required String brandName,
  }) {
    return _remoteDataSource.fetchModelsByBrand(
      brandId: brandId,
      brandName: brandName,
    );
  }
}

