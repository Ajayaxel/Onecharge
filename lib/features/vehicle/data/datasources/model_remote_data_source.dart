import 'package:dio/dio.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/submodel.dart';

class ModelRemoteDataSource {
  ModelRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<List<SubModel>> fetchModelsByBrand({
    required int brandId,
    required String brandName,
  }) async {
    try {
      print('🔵 [ModelRemoteDataSource] Starting fetchModelsByBrand for brandId: $brandId, brandName: $brandName');
      
      final token = await TokenStorage.readToken();
      
      // Build headers - only include Authorization if token exists
      final headers = <String, dynamic>{
        'Accept': 'application/json',
      };
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final url = '${ApiConfig.baseUrl}${ApiConfig.models}';
      print('🔵 [ModelRemoteDataSource] Request URL: $url');
      print('🔵 [ModelRemoteDataSource] Brand ID: $brandId, Brand name: $brandName');
      
      // Fetch all models
      final response = await _dio.get(
        ApiConfig.models,
        options: Options(
          headers: headers,
        ),
      );
      
      print('🔵 [ModelRemoteDataSource] Response Status Code: ${response.statusCode}');
      print('🔵 [ModelRemoteDataSource] Response Data Type: ${response.data.runtimeType}');
      print('🔵 [ModelRemoteDataSource] Response Data: ${response.data}');
      
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final success = data['success'] == true;
        print('✅ [ModelRemoteDataSource] Success flag: $success');
        
        if (success) {
          final dataMap = data['data'] as Map<String, dynamic>?;
          print('📦 [ModelRemoteDataSource] Data map: $dataMap');
          
          final rawModels = (dataMap?['models'] as List<dynamic>? ?? <dynamic>[]);
          print('📋 [ModelRemoteDataSource] Raw models count: ${rawModels.length}');
          
          // Filter models by brand_id matching the selected brandId
          final models = rawModels
              .whereType<Map<String, dynamic>>()
              .where((modelJson) {
                final modelBrandId = (modelJson['brand_id'] as num?)?.toInt();
                return modelBrandId == brandId;
              })
              .map(SubModel.fromJson)
              .where((model) => model.submodelName.isNotEmpty)
              .toList();
          
          print('✅ [ModelRemoteDataSource] Filtered models count for brandId $brandId: ${models.length}');
          print('✅ [ModelRemoteDataSource] Models: ${models.map((m) => '${m.submodelName}').join(', ')}');
          
          return models;
        }
        
        throw ApiException(
          data['message'] as String? ?? 'Unable to load models.',
        );
      }

      print('❌ [ModelRemoteDataSource] Unexpected response type: ${data.runtimeType}');
      throw ApiException('Unexpected response while loading models.');
    } on DioException catch (error) {
      print('❌ [ModelRemoteDataSource] DioException occurred');
      print('❌ [ModelRemoteDataSource] Error type: ${error.type}');
      print('❌ [ModelRemoteDataSource] Error message: ${error.message}');
      print('❌ [ModelRemoteDataSource] Response status code: ${error.response?.statusCode}');
      print('❌ [ModelRemoteDataSource] Response data: ${error.response?.data}');
      print('❌ [ModelRemoteDataSource] Request path: ${error.requestOptions.path}');
      
      final message = error.response?.data is Map<String, dynamic>
          ? (error.response!.data['message'] as String? ??
              'Failed to load models.')
          : 'Failed to load models.';
      print('❌ [ModelRemoteDataSource] Throwing ApiException with message: $message');
      throw ApiException(
        message,
        statusCode: error.response?.statusCode,
      );
    } on ApiException catch (e) {
      print('❌ [ModelRemoteDataSource] ApiException rethrown: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('❌ [ModelRemoteDataSource] Unexpected error: $e');
      print('❌ [ModelRemoteDataSource] Stack trace: $stackTrace');
      throw ApiException('Something went wrong. Please try again.');
    }
  }
}

