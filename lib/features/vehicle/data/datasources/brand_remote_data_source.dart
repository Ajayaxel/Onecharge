import 'package:dio/dio.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/brand.dart';

class BrandRemoteDataSource {
  BrandRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<List<Brand>> fetchBrandsByCategory({
    required int categoryId,
    required String categoryName,
  }) async {
    try {
      print('🔵 [BrandRemoteDataSource] Starting fetchBrandsByCategory for categoryId: $categoryId, categoryName: $categoryName');
      
      final token = await TokenStorage.readToken();
      
      // Build headers - only include Authorization if token exists
      final headers = <String, dynamic>{
        'Accept': 'application/json',
      };
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final url = '${ApiConfig.baseUrl}${ApiConfig.brands}';
      print('🔵 [BrandRemoteDataSource] Request URL: $url');
      print('🔵 [BrandRemoteDataSource] Category ID: $categoryId, Category name: $categoryName');
      
      // Fetch all brands
      final response = await _dio.get(
        ApiConfig.brands,
        options: Options(
          headers: headers,
        ),
      );
      
      print('🔵 [BrandRemoteDataSource] Response Status Code: ${response.statusCode}');
      print('🔵 [BrandRemoteDataSource] Response Data Type: ${response.data.runtimeType}');
      print('🔵 [BrandRemoteDataSource] Response Data: ${response.data}');
      
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final success = data['success'] == true;
        print('✅ [BrandRemoteDataSource] Success flag: $success');
        
        if (success) {
          final dataMap = data['data'] as Map<String, dynamic>?;
          print('📦 [BrandRemoteDataSource] Data map: $dataMap');
          
          final rawBrands = (dataMap?['brands'] as List<dynamic>? ?? <dynamic>[]);
          print('📋 [BrandRemoteDataSource] Raw brands count: ${rawBrands.length}');
          
          // Filter brands by vehicle_type_id matching the selected categoryId
          final brands = rawBrands
              .whereType<Map<String, dynamic>>()
              .where((brandJson) {
                final vehicleTypeId = (brandJson['vehicle_type_id'] as num?)?.toInt();
                return vehicleTypeId == categoryId;
              })
              .map(Brand.fromJson)
              .where((brand) => brand.name.isNotEmpty)
              .toList();
          
          print('✅ [BrandRemoteDataSource] Filtered brands count for categoryId $categoryId: ${brands.length}');
          print('✅ [BrandRemoteDataSource] Brands: ${brands.map((b) => '${b.name} (${b.submodels.length} submodels)').join(', ')}');
          
          return brands;
        }
        
        throw ApiException(
          data['message'] as String? ?? 'Unable to load brands.',
        );
      }

      print('❌ [BrandRemoteDataSource] Unexpected response type: ${data.runtimeType}');
      throw ApiException('Unexpected response while loading brands.');
    } on DioException catch (error) {
      print('❌ [BrandRemoteDataSource] DioException occurred');
      print('❌ [BrandRemoteDataSource] Error type: ${error.type}');
      print('❌ [BrandRemoteDataSource] Error message: ${error.message}');
      print('❌ [BrandRemoteDataSource] Response status code: ${error.response?.statusCode}');
      print('❌ [BrandRemoteDataSource] Response data: ${error.response?.data}');
      print('❌ [BrandRemoteDataSource] Request path: ${error.requestOptions.path}');
      
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response!.data['message'] as String? ??
              'Failed to load brands.')
          : 'Failed to load brands.';
      print('❌ [BrandRemoteDataSource] Throwing ApiException with message: $message');
      throw ApiException(
        message,
        statusCode: error.response?.statusCode,
      );
    } on ApiException catch (e) {
      print('❌ [BrandRemoteDataSource] ApiException rethrown: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('❌ [BrandRemoteDataSource] Unexpected error: $e');
      print('❌ [BrandRemoteDataSource] Stack trace: $stackTrace');
      throw ApiException('Something went wrong. Please try again.');
    }
  }
}

