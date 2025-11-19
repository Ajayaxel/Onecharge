import '../datasources/vehicle_category_remote_data_source.dart';
import '../models/vehicle_category.dart';

class VehicleCategoryRepository {
  VehicleCategoryRepository({
    VehicleCategoryRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? VehicleCategoryRemoteDataSource();

  final VehicleCategoryRemoteDataSource _remoteDataSource;

  Future<List<VehicleCategory>> getVehicleCategories() {
    return _remoteDataSource.fetchVehicleCategories();
  }
}


