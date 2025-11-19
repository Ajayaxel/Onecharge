import 'package:dio/dio.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';

class AuthApiService {
  AuthApiService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: request.toJson(),
      );

      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final message = (data is Map<String, dynamic> ? data['message'] : null) ??
          error.message ??
          'Something went wrong';
      throw ApiException(message.toString(), statusCode: statusCode);
    } catch (_) {
      throw ApiException('Unable to process your request');
    }
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: request.toJson(),
      );

      return RegisterResponse.fromJson(response.data as Map<String, dynamic>);
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
          
          // Print the errors object for debugging
          print('API Errors: $errorsData');
          
          // Convert errors to Map<String, List<String>>
          errorsData.forEach((key, value) {
            if (value is List) {
              errors![key] = value.map((e) => e.toString()).toList();
            } else if (value is String) {
              errors![key] = [value];
            }
          });
          
          // Print parsed errors
          print('Parsed Errors: $errors');
          
          // Format errors into a readable message
          final errorMessages = <String>[];
          errors.forEach((field, messages) {
            for (final msg in messages) {
              // Capitalize field name and format message
              final fieldName = field.isNotEmpty
                  ? field[0].toUpperCase() + field.substring(1)
                  : field;
              errorMessages.add('$fieldName: $msg');
            }
          });
          message = errorMessages.join('\n');
        } else {
          // Fallback to message field
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
      throw ApiException('Unable to process your request');
    }
  }
  Future<UserModel> getCurrentUser() async {
    try {
      final token = await TokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw ApiException('Please login to continue.', statusCode: 401);
      }

      final response = await _dio.get(
        ApiConfig.user,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      // API might return user directly or wrapped in a 'user' key
      if (data.containsKey('user')) {
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        return UserModel.fromJson(data);
      }
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final message = (data is Map<String, dynamic> ? data['message'] : null) ??
          error.message ??
          'Unable to fetch user data';
      throw ApiException(message.toString(), statusCode: statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to fetch user data');
    }
  }

  /// Logout function

  Future<void> logout() async {
    try {
      final token = await TokenStorage.readToken();
      if (token == null || token.isEmpty) {
        return; // No token to logout, skip API call
      }

      await _dio.post(
        ApiConfig.logout,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final message = (data is Map<String, dynamic> ? data['message'] : null) ??
          error.message ??
          'Something went wrong';
      throw ApiException(message.toString(), statusCode: statusCode);
    } catch (_) {
      throw ApiException('Unable to process your request');
    }
  }
}

