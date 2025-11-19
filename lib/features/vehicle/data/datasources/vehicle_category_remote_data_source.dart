import 'package:dio/dio.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/vehicle_category.dart';

class VehicleCategoryRemoteDataSource {
  VehicleCategoryRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<List<VehicleCategory>> fetchVehicleCategories() async {
    try {
      final token = await TokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw  ApiException('Please login to continue.');
      }

      final response = await _dio.get(
        ApiConfig.vehicleCategories,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final success = data['success'] == true;
        if (success) {
          final rawCategories =
              (data['vehicle_categories'] as List<dynamic>? ?? <dynamic>[]);
          final categories = rawCategories
              .whereType<Map<String, dynamic>>()
              .map(VehicleCategory.fromJson)
              .where((category) => category.name.isNotEmpty)
              .toList();
          return categories;
        }
        throw ApiException(
          data['message'] as String? ?? 'Unable to load vehicle categories.',
        );
      }

      throw ApiException('Unexpected response while loading vehicle categories.');
    } on DioException catch (error) {
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response!.data['message'] as String? ??
              'Failed to load vehicle categories.')
          : 'Failed to load vehicle categories.';
      throw ApiException(
        message,
        statusCode: error.response?.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Something went wrong. Please try again.');
    }
  }
}


