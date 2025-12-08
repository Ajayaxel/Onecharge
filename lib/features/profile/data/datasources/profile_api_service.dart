import 'package:dio/dio.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/profile_response.dart';
import '../models/update_password_request.dart';
import '../models/update_password_response.dart';
import '../models/update_profile_request.dart';
import '../../../auth/data/models/login_response.dart';

class ProfileApiService {
  ProfileApiService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<UserModel> getProfile() async {
    try {
      final token = await TokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw ApiException('Please login to continue.', statusCode: 401);
      }

      final response = await _dio.get(
        ApiConfig.profile,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final profileResponse = ProfileResponse.fromJson(data);
      return profileResponse.customer;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final message = (data is Map<String, dynamic> ? data['message'] : null) ??
          error.message ??
          'Unable to fetch profile data';
      throw ApiException(message.toString(), statusCode: statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to fetch profile data');
    }
  }

  Future<UserModel> updateProfile(UpdateProfileRequest request) async {
    try {
      final token = await TokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw ApiException('Please login to continue.', statusCode: 401);
      }

      final response = await _dio.put(
        ApiConfig.profile,
        data: request.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final profileResponse = ProfileResponse.fromJson(data);
      return profileResponse.customer;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      
      // Parse errors object if present
      Map<String, List<String>>? errors;
      String message;
      
      if (data is Map<String, dynamic>) {
        // Check for errors object
        if (data.containsKey('errors') && data['errors'] is Map) {
          final errorsData = data['errors'] as Map<String, dynamic>;
          errors = {};
          
          errorsData.forEach((key, value) {
            if (value is List) {
              errors![key] = value.map((e) => e.toString()).toList();
            } else if (value is String) {
              errors![key] = [value];
            }
          });
          
          final errorMessages = <String>[];
          errors.forEach((field, messages) {
            for (final msg in messages) {
              final fieldName = field.isNotEmpty
                  ? field[0].toUpperCase() + field.substring(1)
                  : field;
              errorMessages.add('$fieldName: $msg');
            }
          });
          message = errorMessages.join('\n');
        } else {
          message = data['message']?.toString() ?? 
              error.message ?? 
              'Something went wrong';
        }
      } else {
        message = error.message ?? 'Something went wrong';
      }
      
      throw ApiException(message, statusCode: statusCode, errors: errors);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to update profile');
    }
  }

  Future<UpdatePasswordResponse> updatePassword(UpdatePasswordRequest request) async {
    try {
      final token = await TokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw ApiException('Please login to continue.', statusCode: 401);
      }

      final response = await _dio.put(
        ApiConfig.updatePassword,
        data: request.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      return UpdatePasswordResponse.fromJson(data);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final message = (data is Map<String, dynamic> ? data['message'] : null) ??
          error.message ??
          'Unable to update password';
      throw ApiException(message.toString(), statusCode: statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to update password');
    }
  }
}

