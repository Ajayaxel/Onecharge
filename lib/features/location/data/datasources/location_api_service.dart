import 'package:dio/dio.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/location_response.dart';

class LocationApiService {
  LocationApiService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<LocationResponse> sendLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final token = await TokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw ApiException('Please login to continue.', statusCode: 401);
      }

      final response = await _dio.post(
        ApiConfig.location,
        data: <String, dynamic>{
          'latitude': latitude,
          'longitude': longitude,
          if (address != null && address.trim().isNotEmpty) 'address': address,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      return LocationResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      String message = 'Unable to save location';

      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ?? message;
      }

      throw ApiException(message, statusCode: status);
    } catch (_) {
      throw ApiException('Unable to save location');
    }
  }
}


