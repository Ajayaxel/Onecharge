import '../datasources/brand_remote_data_source.dart';
import '../models/brand.dart';

class BrandRepository {
  BrandRepository({
    BrandRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? BrandRemoteDataSource();

  final BrandRemoteDataSource _remoteDataSource;

  Future<List<Brand>> getBrandsByCategory({
    required int categoryId,
    required String categoryName,
  }) {
    return _remoteDataSource.fetchBrandsByCategory(
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }
}

