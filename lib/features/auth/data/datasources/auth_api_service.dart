import 'package:dio/dio.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/verify_otp_request.dart';
import '../models/verify_otp_response.dart';
import '../models/resend_otp_request.dart';
import '../models/resend_otp_response.dart';
import '../models/forgot_password_request.dart';
import '../models/forgot_password_response.dart';

class AuthApiService {
  AuthApiService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<LoginResponse> login(LoginRequest request) async {
    print('🌐 [AuthApiService] Login API call initiated');
    print('📍 [AuthApiService] Endpoint: ${ApiConfig.login}');
    print('📝 [AuthApiService] Request data: email=${request.email}');
    
    try {
      print('⏳ [AuthApiService] Sending POST request...');
      final response = await _dio.post(
        ApiConfig.login,
        data: request.toJson(),
      );

      print('✅ [AuthApiService] Response received');
      print('📊 [AuthApiService] Status code: ${response.statusCode}');
      print('📦 [AuthApiService] Response data: ${response.data}');
      
      print('🔄 [AuthApiService] Parsing response...');
      final responseData = response.data as Map<String, dynamic>;
      
      // Handle new API structure where data is nested under 'data' key
      Map<String, dynamic> loginData;
      if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
        final dataMap = responseData['data'] as Map<String, dynamic>;
        
        // Extract customer/user - handle both 'customer' and 'user' keys
        final customerData = dataMap['customer'] as Map<String, dynamic>? ?? 
                           dataMap['user'] as Map<String, dynamic>?;
        
        if (customerData == null) {
          throw Exception('No customer or user data found in response');
        }
        
        // Extract token and other fields from data
        loginData = {
          'message': responseData['message'] as String? ?? '',
          'user': customerData, // Use customer data as user
          'token': dataMap['token'] as String? ?? '',
          'token_type': dataMap['token_type'] as String? ?? 'Bearer',
          'expires_in': dataMap['expires_in'] as int? ?? 0,
        };
        
        final tokenStr = loginData['token']?.toString() ?? '';
        print('📋 [AuthApiService] Extracted token: ${tokenStr.isNotEmpty ? tokenStr.substring(0, tokenStr.length > 20 ? 20 : tokenStr.length) + "..." : "empty"}');
        print('📋 [AuthApiService] Extracted user email: ${customerData['email']}');
      } else {
        // Fallback to old structure (direct mapping)
        loginData = responseData;
      }
      
      final loginResponse = LoginResponse.fromJson(loginData);
      print('✅ [AuthApiService] Response parsed successfully');
      print('👤 [AuthApiService] User: ${loginResponse.user.toString()}');
      print('🎫 [AuthApiService] Token received: ${loginResponse.token.isNotEmpty ? loginResponse.token.substring(0, loginResponse.token.length > 20 ? 20 : loginResponse.token.length) + "..." : "empty"}');
      
      return loginResponse;
    } on DioException catch (error) {
      print('❌ [AuthApiService] DioException occurred');
      print('🔴 [AuthApiService] Error type: ${error.type}');
      print('🔴 [AuthApiService] Error message: ${error.message}');
      
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      
      print('📊 [AuthApiService] Error status code: $statusCode');
      print('📦 [AuthApiService] Error response data: $data');
      
      final message = (data is Map<String, dynamic> ? data['message'] : null) ??
          error.message ??
          'Something went wrong';
      
      print('💬 [AuthApiService] Error message: $message');
      
      // Extract email from error response if available (for email verification errors)
      String? email;
      if (data is Map<String, dynamic>) {
        // Check if email is in data['data']['email'] (nested structure)
        if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          final dataMap = data['data'] as Map<String, dynamic>;
          email = dataMap['email']?.toString();
        }
        // Also check if email is directly in data (flat structure)
        if (email == null && data.containsKey('email')) {
          email = data['email']?.toString();
        }
        if (email != null) {
          print('📧 [AuthApiService] Extracted email from error: $email');
        }
      }
      
      throw ApiException(message.toString(), statusCode: statusCode, email: email);
    } catch (e) {
      print('❌ [AuthApiService] Unexpected error: $e');
      print('🔴 [AuthApiService] Error type: ${e.runtimeType}');
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

  /// Verify OTP function
  Future<VerifyOtpResponse> verifyOtp(VerifyOtpRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.verifyOtp,
        data: request.toJson(),
      );

      return VerifyOtpResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final message = (data is Map<String, dynamic> ? data['message'] : null) ??
          error.message ??
          'Something went wrong';
      throw ApiException(message.toString(), statusCode: statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to process your request');
    }
  }

  /// Resend OTP function
  Future<ResendOtpResponse> resendOtp(ResendOtpRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.resendOtp,
        data: request.toJson(),
      );

      return ResendOtpResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final message = (data is Map<String, dynamic> ? data['message'] : null) ??
          error.message ??
          'Something went wrong';
      throw ApiException(message.toString(), statusCode: statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to process your request');
    }
  }

  /// Forgot Password function
  Future<ForgotPasswordResponse> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.forgotPassword,
        data: request.toJson(),
      );

      return ForgotPasswordResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final message = (data is Map<String, dynamic> ? data['message'] : null) ??
          error.message ??
          'Something went wrong';
      throw ApiException(message.toString(), statusCode: statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unable to process your request');
    }
  }
}

