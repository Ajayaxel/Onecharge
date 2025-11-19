import '../datasources/number_plate_api_service.dart';
import '../models/number_plate_response.dart';

class NumberPlateRepository {
  NumberPlateRepository({NumberPlateApiService? apiService})
    : _apiService = apiService ?? NumberPlateApiService();

  final NumberPlateApiService _apiService;

  Future<NumberPlateResponse> saveNumberPlate({required String plateNumber}) {
    return _apiService.saveNumberPlate(plateNumber: plateNumber);
  }
}
