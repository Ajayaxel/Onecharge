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
      print('🔵 [BrandRemoteDataSource] Starting fetchBrandsByCategory for categoryName: $categoryName');
      
      final token = await TokenStorage.readToken();
      print('🔵 [BrandRemoteDataSource] Token exists: ${token != null && token.isNotEmpty}');
      if (token == null || token.isEmpty) {
        print('❌ [BrandRemoteDataSource] No token found');
        throw ApiException('Please login to continue.');
      }

      final url = '${ApiConfig.baseUrl}${ApiConfig.brands}';
      print('🔵 [BrandRemoteDataSource] Request URL: $url');
      print('🔵 [BrandRemoteDataSource] Category name: $categoryName');
      
      // Fetch all brands without query parameters
      final response = await _dio.get(
        ApiConfig.brands,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      print('🔵 [BrandRemoteDataSource] Response Status Code: ${response.statusCode}');
      print('🔵 [BrandRemoteDataSource] Response Data Type: ${response.data.runtimeType}');
      print('🔵 [BrandRemoteDataSource] Response Data: ${response.data}');
      
      final data = response.data;

      if (data is Map<String, dynamic>) {
        print('🔵 [BrandRemoteDataSource] Response is Map<String, dynamic>');
        print('🔵 [BrandRemoteDataSource] Response keys: ${data.keys.toList()}');
        
        // Map category name to API key (car, bike, test)
        final categoryKey = _mapCategoryNameToKey(categoryName);
        print('🔵 [BrandRemoteDataSource] Mapped category key: $categoryKey');

        if (data.containsKey(categoryKey)) {
          final rawBrands = data[categoryKey];
          if (rawBrands is List) {
            print('✅ [BrandRemoteDataSource] Found brands list for $categoryKey with ${rawBrands.length} entries');
            final brands = rawBrands
                .whereType<Map<String, dynamic>>()
                .map(Brand.fromJson)
                .where((brand) => brand.name.isNotEmpty && brand.logo.isNotEmpty)
                .toList();
            print('✅ [BrandRemoteDataSource] Parsed brands count: ${brands.length}');
            print('✅ [BrandRemoteDataSource] Brands: ${brands.map((b) => '${b.name} (${b.submodels.length} submodels)').toList()}');
            return brands;
          }
          print('⚠️ [BrandRemoteDataSource] Value for $categoryKey is not a list: ${rawBrands.runtimeType}');
        } else {
          print('⚠️ [BrandRemoteDataSource] Key $categoryKey not found in response');
        }

        final availableKeys = data.keys.join(', ');
        throw ApiException(
          'No brands found for category "$categoryName". Available keys: $availableKeys',
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

String _mapCategoryNameToKey(String categoryName) {
  final normalized = categoryName.trim().toLowerCase();
  
  // Map common category names to API keys
  if (normalized.contains('car') || normalized == 'car') {
    return 'car';
  } else if (normalized.contains('bike') || normalized == 'bike') {
    return 'bike';
  } else if (normalized.contains('test') || normalized == 'test') {
    return 'test';
  } else if (normalized.contains('scooter')) {
    // Scooter might map to bike or test, defaulting to bike
    return 'bike';
  }
  
  // Default fallback - try to match any key that contains the category name
  return normalized;
}

