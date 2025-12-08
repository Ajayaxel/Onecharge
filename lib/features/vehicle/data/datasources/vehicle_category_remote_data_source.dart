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
      
      // Build headers - only include Authorization if token exists
      final headers = <String, dynamic>{
        'Accept': 'application/json',
      };
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _dio.get(
        ApiConfig.vehicleCategories,
        options: Options(
          headers: headers,
        ),
      );
      print('Vehicle categories response: ${response.data}');
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final success = data['success'] == true;
        print('✅ Success flag: $success');
        if (success) {
          final dataMap = data['data'] as Map<String, dynamic>?;
          print('📦 Data map: $dataMap');
          final rawCategories =
              (dataMap?['vehicle_types'] as List<dynamic>? ?? <dynamic>[]);
          print('📋 Raw categories count: ${rawCategories.length}');
          
          final categories = rawCategories
              .whereType<Map<String, dynamic>>()
              .where((json) {
                // Filter by status if it exists, otherwise include all
                final status = json['status'];
                final name = json['name'] as String? ?? '';
                final hasValidName = name.trim().isNotEmpty;
                final isActive = status == null || status == true;
                return hasValidName && isActive;
              })
              .map(VehicleCategory.fromJson)
              .toList();
          
          print('✅ Parsed categories count: ${categories.length}');
          print('📝 Categories: ${categories.map((c) => '${c.id}: ${c.name}').join(', ')}');
          
          return categories;
        }
        throw ApiException(
          data['message'] as String? ?? 'Unable to load vehicle categories.',
        );
      }

      throw ApiException('Unexpected response while loading vehicle categories.');
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response!.data['message'] as String? ??
              'Failed to load vehicle categories.')
          : 'Failed to load vehicle categories.';
      throw ApiException(
        message,
        statusCode: statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Something went wrong. Please try again.');
    }
  }
}


